import 'dart:math';

class PaymentService {
  // Ödeme işlemini simüle eden metot
  Future<bool> processPayment({
    required double amount,
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cvv,
  }) async {
    // Gerçek bir ödeme işlemi için burada ödeme sağlayıcısına istek yapılır
    // Şimdilik simüle ediyoruz
    
    // Kart bilgilerini doğrula
    if (!_validateCardNumber(cardNumber)) {
      return false;
    }
    
    if (!_validateExpiryDate(expiryDate)) {
      return false;
    }
    
    if (!_validateCVV(cvv)) {
      return false;
    }
    
    // İşlem simülasyonu için gecikme
    await Future.delayed(Duration(seconds: 2));
    
    // Rastgele başarı/başarısızlık (gerçek uygulamada bu kısım olmaz)
    // %90 başarı oranı
    final random = Random();
    return random.nextDouble() < 0.9;
  }
  
  // Kart numarası doğrulama (Luhn algoritması)
  bool _validateCardNumber(String cardNumber) {
    if (cardNumber.length != 16) {
      return false;
    }
    
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10 == 0);
  }
  
  // Son kullanma tarihi doğrulama
  bool _validateExpiryDate(String expiryDate) {
    // AA/YY formatı kontrolü
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiryDate)) {
      return false;
    }
    
    List<String> parts = expiryDate.split('/');
    int month = int.parse(parts[0]);
    int year = int.parse(parts[1]) + 2000; // 2 haneli yılı 4 haneye çevir
    
    DateTime now = DateTime.now();
    DateTime expiryDateTime = DateTime(year, month + 1, 0); // Ayın son günü
    
    return expiryDateTime.isAfter(now);
  }
  
  // CVV doğrulama
  bool _validateCVV(String cvv) {
    return RegExp(r'^[0-9]{3,4}$').hasMatch(cvv);
  }
}
