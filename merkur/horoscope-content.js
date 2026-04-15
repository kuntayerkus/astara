const HOROSCOPE_COPY = {
    sun: {
        Aries: "Doğuştan lidersin ya da sadece dik kafalı. Zaten her şeyi sen biliyorsun, değil mi? Sabrın yok, her şey 'hemen şimdi' olmalı.",
        Taurus: "Konfor alanın o kadar geniş ki dışarı çıkman yıllar alıyor. Yemeğe ve lükse düşkünsün, inatçılığından bahsetmiyorum bile.",
        Gemini: "Bir dediğin diğerini tutmuyor. Zihnin o kadar hızlı çalışıyor ki sen bile yetişemiyorsun. Eğlencelisin ama biraz da dedikoducu.",
        Cancer: "Duygu küpüsün. Sürekli geçmişi anıp, eski mesajları okuyup ağlıyorsun. İnsanları manipüle etme yeteneğin şapka çıkartır.",
        Leo: "Dünya senin etrafında dönüyor sanıyorsun. Gösterişi seviyorsun, iltifatla çalışan bir makine gibisin. Ama kalbin gerçekten çok büyük.",
        Virgo: "Mükemmeliyetçilikten kendi hayatını zindana çevirdin. Her detayı eleştiriyorsun. Acaba biraz rahatlaman mı gerekiyor?",
        Libra: "Estetik ve güzellik senin için her şey. Karar vermen yıllar sürüyor. 'Sen bilirsin' demekten vazgeç artık.",
        Scorpio: "Karanlık, gizemli ve kindarsın. Birisi sana yanlış yaptıysa, 10 yıl sonra bile unutmazsın. Ama tutkun ve derinliğin büyüleyici.",
        Sagittarius: "Özgürlüğüne düşkünsün, bağlanmaktan ölesiye korkuyorsun. Fevrisin, ağzından çıkanı kulağın duymuyor. Her an valizini toplayıp gidebilirsin.",
        Capricorn: "İşkoliksin. Duygularını excel tablosuna dökmek istiyorsun. Hedeflerin var ama biraz da yaşamayı hatırlasan fena olmaz.",
        Aquarius: "Marjinal görünmek için özel çaba harcıyorsun. İnsanları seviyorsun ama toplu ortamlara tahammülün yok. Tuhafsın.",
        Pisces: "Kurban psikolojisinden çıkamıyorsun. Hayal dünyasında yaşıyor, gerçekleri görmezden geliyorsun. Sezgilerin çok kuvvetli."
    },
    moon: {
        Aries: "İç dünyanda fırtınalar kopuyor, öfken bir anda parlayıp sönüyor. Tahammül seviyen sıfıra yakın.",
        Taurus: "Duygusal güvenliğe ihtiyacın çok yüksek. Yeniliklerden ölesiye korkuyorsun. Eski olan her şeye bağımlısın.",
        Gemini: "Duygularını bile mantıkla çözmeye çalışıyorsun. İçin içini yiyor ama susmuyorsun.",
        Cancer: "Bağlandın mı körü körüne bağlanıyorsun. Güvenli liman arayışın bazen seni zehirli ilişkilerde tutuyor.",
        Leo: "İlgi görmediğinde duygusal krizlere giriyorsun. Dram senin göbek adın. Reddedilmeyi asla kabullenemezsin.",
        Virgo: "Kendi kendini yiyip bitiriyorsun. Endişe katsayın her zaman çok yüksek. Rahat bir nefes almaya ne dersin?",
        Libra: "Yalnız kalmak en büyük kabusun. İkili ilişkilere bağımlısın. Uyum uğruna sürekli taviz veriyorsun.",
        Scorpio: "Kıskançlık krizlerinde üstüne yok. Duygularını bir sır gibi saklıyorsun. İntikam duygun seni içten içe yavaş yavaş bitiriyor.",
        Sagittarius: "Duygusal baskı hissettiğin an arkanı dönüp kaçıyorsun. Derin yüzleşmeleri sevmiyor, hep iyi hissetmek istiyorsun.",
        Capricorn: "Duygularını bir beton duvarın arkasına gizledin. Kimseye güvenmiyorsun. Acı çeksen bile güçlü görünmek zorundasın.",
        Aquarius: "Duygusal kopukluk senin uzmanlık alanın. Seni anlamak neredeyse imkansız. Beklenmedik anlarda buz gibi soğuyabilirsin.",
        Pisces: "Fazla empatiksin, başkalarının dertlerini kendi derdin sanıp depresyona giriyorsun. Duygusal sınırların paramparça."
    },
    ascendant: {
        Aries: "Dışarıdan bakıldığında hep acelesi olan, hafif burnu havada biri gibisin. İnsanlar seninle tartışmaya girmekten çekiniyor çünkü patlamaya hazırsın.",
        Taurus: "İlk intiban aşırı yavaş ve uyuşuk olduğun yönünde. İnsanlar seni zararsız sanıyor ama aslında sınırlarına girilirse tam bir inatçı keçisin.",
        Gemini: "Ortamlara girdiğinde durmadan konuşan, bir saniye yerinde duramayan tip sensin. Çok şey biliyormuş gibi yapıp hiçbir şeye tam odaklanamıyorsun.",
        Cancer: "Dışarıya yansıttığın o 'anaç ve masum' tavır aslında en büyük zırhın. İnsanlar sana hemen güveniyor, sen de bunu gizli bir silah gibi kullanıyorsun.",
        Leo: "Girdiğin odada herkes sana baksın istiyorsun. Saçların, yürüyüşün, havan... Hepsi 'ben buradayım' diye bağırıyor. Bazen bu fazla yorucu olabiliyor.",
        Virgo: "İnsanlar seni ilk gördüğünde 'ne kadar soğuk ve eleştirel' diye düşünüyor. Haklılar da. Herkesi kafanın içinde baştan aşağı puanlıyorsun.",
        Libra: "Aşırı kibar, tatlı ve uyumlu masken herkesi kandırıyor. Aslında sadece çatışmadan kaçmak için gülümsüyorsun. Gerçek bir politikacısın.",
        Scorpio: "Gözlerinle insanları delip geçiyorsun. Varlığın ortamda bir gerginlik yaratıyor çünkü kimseye kolay güvenmediğin her halinden belli oluyor.",
        Sagittarius: "Aşırı neşeli, patavatsız ve sınır tanımaz bir ilk intiban var. İnsanlar seninle eğleniyor ama kimse seni tam olarak ciddiye alamıyor.",
        Capricorn: "Ortama bir CEO gibi giriyorsun. Mesafe ve ciddiyet senin kalkanın. Eğlenmeyi bilmeyen, sürekli iş düşünen mesafeli biri gibi görünüyorsun.",
        Aquarius: "Herkesin yaptığını yapmamak için özel çaba harcıyorsun. Garip giyiniyor, farklı davranıyor ve kasıtlı olarak 'ben sürüden değilim' imajı çiziyorsun.",
        Pisces: "Gözlerin hep uzaklara dalıyor. Etrafında ne olup bittiğinden bihaber gibisin. İnsanlar senin sürekli yardıma veya uyanmaya muhtaç olduğunu düşünüyor."
    },
    synthesis: "Kozmik Sentez (Karanlık Yüzün & İlişki Dinamikleri):\\nHaritandaki bu Güneş, Ay ve Yükselen kombinasyonu tam bir kaos yaratıyor. Dışarıya gösterdiğin o maske ile iç dünyandaki fırtınalar, seni sürekli aynı zehirli ilişki döngülerine çekiyor. Kendi kendini sabote etme konusunda bir dünya markasısın. Sürekli onay arıyor, kurtarıcı rolü oynayabileceğin veya seni manipüle edecek insanlara bilerek çekiliyor ve sonra 'neden hep aynı şeyleri yaşıyorum' diye ağlıyorsun. Potansiyelin çok yüksek ama bu gölgelerinle pratik bir şekilde yüzleşmediğin sürece olduğun yerde patinaj çekmeye devam edeceksin.",
    cta: "Haritanda ilişkilerini sabote eden ve potansiyelini engelleyen çok kritik açılar var. Döngüyü kırmak, kendi gerçeğinle yüzleşmek ve profesyonel destek almak için hemen danışmanlık al."
};

const ZODIAC_TR = {
    Aries: { name: "Koç", icon: "♈", color: "from-red-500 to-orange-500" },
    Taurus: { name: "Boğa", icon: "♉", color: "from-emerald-500 to-green-600" },
    Gemini: { name: "İkizler", icon: "♊", color: "from-yellow-400 to-orange-400" },
    Cancer: { name: "Yengeç", icon: "♋", color: "from-slate-300 to-slate-500" },
    Leo: { name: "Aslan", icon: "♌", color: "from-orange-400 to-red-500" },
    Virgo: { name: "Başak", icon: "♍", color: "from-emerald-600 to-teal-700" },
    Libra: { name: "Terazi", icon: "♎", color: "from-pink-400 to-rose-400" },
    Scorpio: { name: "Akrep", icon: "♏", color: "from-purple-800 to-slate-900" },
    Sagittarius: { name: "Yay", icon: "♐", color: "from-purple-500 to-indigo-500" },
    Capricorn: { name: "Oğlak", icon: "♑", color: "from-stone-600 to-stone-800" },
    Aquarius: { name: "Kova", icon: "♒", color: "from-cyan-400 to-blue-500" },
    Pisces: { name: "Balık", icon: "♓", color: "from-indigo-400 to-cyan-400" }
};
