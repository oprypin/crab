module ARM
  def arm_single_data_swap(instr : Word) : Nil
    byte_quantity = bit?(instr, 22)
    rn = bits(instr, 16..19)
    rd = bits(instr, 12..15)
    rm = bits(instr, 0..3)
    if byte_quantity
      tmp = @gba.bus[@r[rn]]
      @gba.bus[@r[rn]] = @r[rm].to_u8!
      @r[rd] = tmp.to_u32
    else
      tmp = @gba.bus.read_word @r[rn]
      @gba.bus[@r[rn]] = @r[rm]
      @r[rd] = tmp
    end
  end
end
