import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ai_provider.dart';

class AIAdvisorScreen extends StatefulWidget {
  const AIAdvisorScreen({super.key});

  @override
  State<AIAdvisorScreen> createState() => _AIAdvisorScreenState();
}

class _AIAdvisorScreenState extends State<AIAdvisorScreen> {
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Consultor IA',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          return Column(
            children: [
              // Recomendações automáticas
              if (aiProvider.recommendations.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recomendações Personalizadas',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...aiProvider.recommendations.map((recommendation) => 
                        _buildRecommendationCard(recommendation.description, recommendation.type.name)),
                    ],
                  ),
                ),
              
              // Campo de pergunta
              Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faça uma pergunta sobre suas finanças',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _questionController,
                            decoration: InputDecoration(
                              hintText: 'Ex: Como posso economizar mais?',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton(
                          heroTag: "ai_advisor_fab",
                          onPressed: () => _askQuestion(aiProvider),
                          backgroundColor: Colors.blue.shade600,
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Histórico de conversas
              Expanded(
                child: aiProvider.chatHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Faça sua primeira pergunta!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A IA está pronta para ajudar com suas finanças',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: aiProvider.chatHistory.length,
                        itemBuilder: (context, index) {
                          final chat = aiProvider.chatHistory[index];
                          return _buildChatBubble(
                            chat['question'] as String,
                            chat['answer'] as String,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(String content, String type) {
    Color cardColor;
    IconData icon;
    
    switch (type.toLowerCase()) {
      case 'saving':
        cardColor = Colors.green.shade100;
        icon = Icons.savings;
        break;
      case 'warning':
        cardColor = Colors.orange.shade100;
        icon = Icons.warning;
        break;
      case 'investment':
        cardColor = Colors.blue.shade100;
        icon = Icons.trending_up;
        break;
      default:
        cardColor = Colors.grey.shade100;
        icon = Icons.lightbulb;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String question, String answer) {
    return Column(
      children: [
        // Pergunta do usuário
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, left: 50),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        // Resposta da IA
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, right: 50),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _askQuestion(AIProvider aiProvider) {
    if (_questionController.text.trim().isNotEmpty) {
      aiProvider.askQuestion(_questionController.text.trim());
      _questionController.clear();
    }
  }
}
