import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/group_provider.dart';
import '../services/whatsapp_integration_service.dart';

class WhatsAppIntegrationScreen extends StatefulWidget {
  const WhatsAppIntegrationScreen({super.key});

  @override
  State<WhatsAppIntegrationScreen> createState() => _WhatsAppIntegrationScreenState();
}

class _WhatsAppIntegrationScreenState extends State<WhatsAppIntegrationScreen> {
  static const String _twilioSandboxNumber = '+14155238886';

  bool _isLoading = false;
  bool _waitingVerification = false;
  String? _verificationCode;
  Map<String, dynamic>? _integrationStatus;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingIntegration();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingIntegration() async {
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.selectedGroupId == null) return;

    setState(() => _isLoading = true);

    final status = await WhatsAppIntegrationService.getIntegrationStatus(
      groupProvider.selectedGroupId!,
    );

    if (mounted) {
      setState(() {
        _integrationStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _startVinculacao() async {
    setState(() => _isLoading = true);

    final groupProvider = context.read<GroupProvider>();
    final code = await WhatsAppIntegrationService.createIntegration(
      groupProvider.selectedGroupId!,
    );

    if (code == null || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _verificationCode = code;
      _isLoading = false;
      _waitingVerification = true;
    });

    final message = Uri.encodeComponent('vincular $code');
    final whatsappUrl = Uri.parse(
      'https://wa.me/${_twilioSandboxNumber.replaceAll('+', '')}?text=$message',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o WhatsApp. Envie manualmente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final groupProvider = context.read<GroupProvider>();
      if (groupProvider.selectedGroupId == null) return;

      final status = await WhatsAppIntegrationService.getIntegrationStatus(
        groupProvider.selectedGroupId!,
      );

      if (status != null && status['is_verified'] == true && mounted) {
        _pollingTimer?.cancel();
        setState(() {
          _integrationStatus = status;
          _waitingVerification = false;
          _verificationCode = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp vinculado com sucesso!'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    });
  }

  Future<void> _removeIntegration() async {
    if (_integrationStatus == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar WhatsApp'),
        content: const Text('Tem certeza que deseja desconectar o WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desconectar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    await WhatsAppIntegrationService.removeIntegration(_integrationStatus!['id']);

    if (mounted) {
      setState(() {
        _integrationStatus = null;
        _verificationCode = null;
        _waitingVerification = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Integração WhatsApp',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_integrationStatus?['is_verified'] == true)
                    _buildConnectedCard()
                  else if (_waitingVerification)
                    _buildWaitingCard()
                  else
                    _buildVincularButton(),
                  const SizedBox(height: 24),
                  _buildInstructionsCard(),
                  const SizedBox(height: 16),
                  _buildCommandsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            'Lance despesas e entradas via WhatsApp',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie mensagens de texto ou áudio para registrar transações sem abrir o app.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WhatsApp Conectado',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      _integrationStatus?['phone_number'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _removeIntegration,
              icon: const Icon(Icons.link_off, color: Colors.red),
              label: const Text('Desconectar', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Color(0xFF25D366),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando vinculação...',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envie a mensagem no WhatsApp que foi aberto.\nA vinculação será confirmada automaticamente.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startVinculacao,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reenviar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'vincular $_verificationCode'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comando copiado!'),
                        backgroundColor: Color(0xFF25D366),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVincularButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.chat_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Nenhum WhatsApp vinculado',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão abaixo para vincular automaticamente.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startVinculacao,
              icon: const Icon(Icons.chat, size: 22),
              label: const Text('Vincular WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formas de Lançamento',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.text_fields,
            'Texto',
            'Envie: "despesa 50 mercado"',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.mic,
            'Áudio',
            'Grave: "Gastei 150 no restaurante"',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.account_balance_wallet,
            'Entrada',
            'Envie: "entrada 2000 salário"',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            Icons.bar_chart,
            'Consulta',
            'Envie: "saldo" ou "resumo"',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommandsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comandos Disponíveis',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildCommandItem('despesa [valor] [descrição]', 'Registra uma despesa'),
          _buildCommandItem('entrada [valor] [descrição]', 'Registra uma entrada'),
          _buildCommandItem('saldo', 'Mostra resumo do mês'),
          _buildCommandItem('ajuda', 'Lista todos os comandos'),
          _buildCommandItem('desvincular', 'Remove a conexão'),
        ],
      ),
    );
  }

  Widget _buildCommandItem(String command, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              command,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF128C7E),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
