// Denormalize 8-bit color channels to integers in the range 0 to 255.
ivec4 floatsToBytes(vec4 inputFloats, bool littleEndian) {
  ivec4 bytes = ivec4(inputFloats * 255.0);
  return (
    littleEndian
    ? bytes.abgr
    : bytes
  );
}

// Break the four bytes down into an array of 32 bits.
void bytesToBits(const in ivec4 bytes, out bool bits[32]) {
  for (int channelIndex = 0; channelIndex < 4; ++channelIndex) {
    float acc = float(bytes[channelIndex]);
    for (int indexInByte = 7; indexInByte >= 0; --indexInByte) {
      float powerOfTwo = exp2(float(indexInByte));
      bool bit = acc >= powerOfTwo;
      bits[channelIndex * 8 + (7 - indexInByte)] = bit;
      acc = mod(acc, powerOfTwo);
    }
  }
}

// Compute the exponent of the 32-bit float.
float getExponent(bool bits[32]) {
  const int startIndex = 1;
  const int bitStringLength = 8;
  const int endBeforeIndex = startIndex + bitStringLength;
  float acc = 0.0;
  int pow2 = bitStringLength - 1;
  for (int bitIndex = startIndex; bitIndex < endBeforeIndex; ++bitIndex) {
    acc += float(bits[bitIndex]) * exp2(float(pow2--));
  }
  return acc;
}

// Compute the mantissa of the 32-bit float.
float getMantissa(bool bits[32], bool subnormal) {
  const int startIndex = 9;
  const int bitStringLength = 23;
  const int endBeforeIndex = startIndex + bitStringLength;
  // Leading/implicit/hidden bit convention:
  // If the number is not subnormal (with exponent 0), we add a leading 1 digit.
  float acc = float(!subnormal) * exp2(float(bitStringLength));
  int pow2 = bitStringLength - 1;
  for (int bitIndex = startIndex; bitIndex < endBeforeIndex; ++bitIndex) {
    acc += float(bits[bitIndex]) * exp2(float(pow2--));
  }
  return acc;
}

// Parse the float from its 32 bits.
float bitsToFloat(bool bits[32]) {
  float signBit = float(bits[0]) * -2.0 + 1.0;
  float exponent = getExponent(bits);
  bool subnormal = abs(exponent - 0.0) < 0.01;
  float mantissa = getMantissa(bits, subnormal);
  float exponentBias = 127.0;
  return signBit * mantissa * exp2(exponent - exponentBias - 23.0);
}

// Decode a 32-bit float from the RGBA color channels of a texel.
float rgbaToFloat(vec4 texelRGBA, bool littleEndian) {
  ivec4 rgbaBytes = floatsToBytes(texelRGBA, littleEndian);
  bool bits[32];
  bytesToBits(rgbaBytes, bits);
  return bitsToFloat(bits);
}

#pragma glslify: export(rgbaToFloat)
