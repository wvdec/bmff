# coding: utf-8
# vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 autoindent:

module BMFF::BinaryAccessor
  BYTE_ORDER = "\xFE\xFF".unpack("s").first == 0xFEFF ? :be : :le

  def get_int8
    _read(1).unpack("c").first
  end

  def get_uint8
    _read(1).unpack("C").first
  end

  def get_int16
    flip_byte_if_needed(_read(2)).unpack("s").first
  end

  def get_uint16
    _read(2).unpack("n").first
  end

  def get_uint24
    (get_uint8 << 16) | get_uint16
  end

  def get_int32
    flip_byte_if_needed(_read(4)).unpack("l").first
  end

  def get_uint32
    _read(4).unpack("N").first
  end

  def get_int64
    b1 = flip_byte_if_needed(_read(4)).unpack("l").first
    b2 = _read(4).unpack("N").first
    (b1 << 32) | b2
  end

  def get_uint64
    b1, b2 = _read(8).unpack("N2")
    (b1 << 32) | b2
  end

  def get_ascii(size)
    _read(size).unpack("a*").first
  end

  def get_byte(size = 1)
    _read(size)
  end

  # Null-terminated string
  # An encoding of this string is maybe UTF-8.
  # Other encodings are possible.
  # (e.g. Apple Media Handler outputs non UTF-8 string)
  def get_null_terminated_string(max_byte = nil)
    buffer = ""
    read_byte = 0
    until eof?
      b = read(1)
      read_byte += 1
      break if b == "\x00"
      buffer << b
      break if max_byte && read_byte >= max_byte
    end
    # UTF-8, Shift_JIS or ASCII-8BIT (fallback)
    %w(UTF-8 Shift_JIS ASCII-8BIT).each do |encoding|
      buffer.force_encoding(encoding)
      break if buffer.valid_encoding?
    end
    buffer
  end

  # Return ISO 639-2/T code
  # Each character is compressed into 5-bit width.
  # The bit 5 and 6 values are always 1. The bit 7 value is always 0.
  def get_iso639_2_language
    lang = get_uint16
    c1 = (lang >> 10) & 0x1F | 0x60
    c2 = (lang >>  5) & 0x1F | 0x60
    c3 =  lang        & 0x1F | 0x60
    sprintf("%c%c%c", c1, c2, c3)
  end

  def get_uuid
    # TODO: create and return UUID type.
    _read(16)
  end

  private
  def flip_byte_if_needed(data)
    if BYTE_ORDER == :le
      return data.force_encoding("ascii-8bit").reverse
    end
    return data
  end

  def _read(size)
    raise TypeError unless size.kind_of?(Integer)
    raise RangeError if size <= 0
    data = read(size)
    raise EOFError unless data
    raise EOFError unless data.bytesize == size
    data
  end
end
