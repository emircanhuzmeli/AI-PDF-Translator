require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const axios = require('axios');

const app = express();

// 1. SİBER GÜVENLİK KATMANLARI
app.use(helmet()); 
app.use(express.json({ limit: '10mb' })); 
app.use(cors()); 

// 2. RATE LIMITING (DDoS ve Kota Saldırısı Koruması)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 30, 
  message: { error: 'Çok fazla istek atıldı. Lütfen 15 dakika sonra tekrar deneyin.' }
});
app.use('/api/', limiter);

// 3. AUTHENTICATION MIDDLEWARE
const authenticateApp = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const expectedToken = `Bearer ${process.env.APP_SECRET_TOKEN}`;

  if (!authHeader || authHeader !== expectedToken) {
    return res.status(401).json({ error: 'Yetkisiz erişim! Geçersiz uygulama tokeni.' });
  }
  next();
};

// 4. GÜVENLİ ÇEVİRİ ENDPOINT'İ
app.post('/api/v1/translate', authenticateApp, async (req, res) => {
  try {
    const { systemPrompt, userPrompt } = req.body;

    if (!userPrompt) {
      return res.status(400).json({ error: 'Çevrilecek metin eksik.' });
    }

    const response = await axios.post(
      'https://api.deepseek.com/chat/completions',
      {
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: systemPrompt || 'You are a translation assistant.' },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.1
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`
        },
        timeout: 45000
      }
    );

    const translatedContent = response.data.choices[0].message.content;
    return res.json({ success: true, result: translatedContent });

  } catch (error) {
    console.error('Backend AI Hatası:', error.response?.data || error.message);
    return res.status(500).json({ 
      error: 'Sunucu tarafında çeviri işlenirken bir hata oluştu.' 
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🔒 Güvenli Backend Servisi ${PORT} portunda aktif!`);
});
