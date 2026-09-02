import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:bs58/bs58.dart';
import 'bip39_words.dart';

class CatWalletGenerator {
  // Catcoin Constants (from research)
  static const int networkVersion = 0x15; // 21 -> Starts with '9'
  static const int privateKeyPrefix = 0x95; // 149

  static final ECDomainParameters _params = ECCurve_secp256k1();

  /// Generates a new wallet with Mnemonic (24 words)
  static Map<String, String> generateWallet() {
    // 1. Generate Entropy (256 bits for 24 words)
    final entropy = _generateEntropy(32);

    // 2. Convert to Mnemonic
    final mnemonic = _entropyToMnemonic(entropy);

    return importWalletFromMnemonic(mnemonic);
  }

  /// Recovers a wallet from a valid Mnemonic phrase
  static Map<String, String> importWalletFromMnemonic(String mnemonic) {
    // 3. Generate Seed from Mnemonic
    final seed = _mnemonicToSeed(mnemonic);

    // 4. Derive Private Key
    // Detailed HD wallet derivation (BIP32/44) is better but complex without library.
    // For now, we hash the seed to getting a valid 32-byte private key.
    final privateKeyBytes = sha256.convert(seed).bytes;
    final privateKeyBigInt = BigInt.parse(
        privateKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);

    // 5. Derive Public Key
    final publicKeyPoint = _params.G * privateKeyBigInt;
    final publicKeyBytes = publicKeyPoint!.getEncoded(false); // Uncompressed

    // 6. Generate Address (Base58Check(Version + Hash160(PubKey)))
    final address = _generateAddress(publicKeyBytes);

    // 7. Generate WIF
    final wif = _generateWIF(Uint8List.fromList(privateKeyBytes));

    return {
      'mnemonic': mnemonic,
      'privateKey': wif,
      'address': address,
      'privateKeyHex': privateKeyBigInt.toRadixString(16),
    };
  }

  static Uint8List _generateEntropy(int length) {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(255)))));
    return secureRandom.nextBytes(length);
  }

  static String _entropyToMnemonic(Uint8List entropy) {
    // Convert bytes to binary string
    String binary =
        entropy.map((b) => b.toRadixString(2).padLeft(8, '0')).join();

    // Checksum: First (len / 32) bits of SHA256(entropy)
    final hash = sha256.convert(entropy).bytes;
    final checksumLength = entropy.length * 8 ~/ 32;
    String hashBinary =
        hash.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
    binary += hashBinary.substring(0, checksumLength); // Append checksum bits

    // Split into 11-bit chunks
    final chunks = <String>[];
    for (int i = 0; i < binary.length; i += 11) {
      chunks.add(binary.substring(i, i + 11));
    }

    // Map to words
    return chunks
        .map((chunk) => bip39Words[int.parse(chunk, radix: 2)])
        .join(' ');
  }

  static Uint8List _mnemonicToSeed(String mnemonic, [String passphrase = '']) {
    final salt = Uint8List.fromList('mnemonic$passphrase'.codeUnits);
    final pbkdf2 = KeyDerivator('SHA-512/HMAC/PBKDF2');
    pbkdf2
        .init(Pbkdf2Parameters(salt, 2048, 64)); // 2048 rounds, 64 byte output
    return pbkdf2.process(Uint8List.fromList(mnemonic.codeUnits));
  }

  static String _generateAddress(Uint8List publicKey) {
    // SHA256(PubKey)
    final s256 = sha256.convert(publicKey).bytes;

    // RIPEMD160(SHA256(PubKey))
    final digest = RIPEMD160Digest();
    final ripemd160 = digest.process(Uint8List.fromList(s256));

    // Version + Hash160
    final payload = Uint8List(1 + ripemd160.length);
    payload[0] = networkVersion;
    payload.setRange(1, payload.length, ripemd160);

    // Base58Check Encode
    return base58.encode(Uint8List.fromList(_addChecksum(payload)));
  }

  static String _generateWIF(Uint8List privateKey) {
    // Prefix + PrivKey
    final payload = Uint8List(1 + privateKey.length);
    payload[0] = privateKeyPrefix;
    payload.setRange(1, payload.length, privateKey);

    // Base58Check Encode
    return base58.encode(Uint8List.fromList(_addChecksum(payload)));
  }

  static List<int> _addChecksum(Uint8List payload) {
    // Double SHA256 for checksum
    final hash1 = sha256.convert(payload).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    final checksum = hash2.sublist(0, 4);

    return [...payload, ...checksum];
  }
}


