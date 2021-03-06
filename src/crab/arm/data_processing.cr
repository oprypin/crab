module ARM
  def arm_data_processing(instr : Word) : Nil
    imm_flag = bit?(instr, 25)
    opcode = bits(instr, 21..24)
    set_conditions = bit?(instr, 20)
    rn = bits(instr, 16..19)
    rd = bits(instr, 12..15)
    # The PC value will be the address of the instruction, plus 8 or 12 bytes due to instruction
    # prefetching. If the shift amount is specified in the instruction, the PC will be 8 bytes
    # ahead. If a register is used to specify the shift amount the PC will be 12 bytes ahead.
    pc_reads_12_ahead = !imm_flag && bit?(instr, 4)
    @r[15] &+= 4 if pc_reads_12_ahead
    barrel_shifter_carry_out = @cpsr.carry
    operand_2 = if imm_flag # Operand 2 is an immediate
                  immediate_offset bits(instr, 0..11), pointerof(barrel_shifter_carry_out)
                else # Operand 2 is a register
                  rotate_register bits(instr, 0..11), pointerof(barrel_shifter_carry_out)
                end
    case opcode
    when 0b0000 # AND
      set_reg(rd, @r[rn] & operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    when 0b0001 # EOR
      set_reg(rd, @r[rn] ^ operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    when 0b0010 # SUB
      set_reg(rd, sub(@r[rn], operand_2, set_conditions))
    when 0b0011 # RSB
      set_reg(rd, sub(operand_2, @r[rn], set_conditions))
    when 0b0100 # ADD
      set_reg(rd, add(@r[rn], operand_2, set_conditions))
    when 0b0101 # ADC
      set_reg(rd, adc(@r[rn], operand_2, set_conditions))
    when 0b0110 # SBC
      set_reg(rd, sbc(@r[rn], operand_2, set_conditions))
    when 0b0111 # RSC
      set_reg(rd, sbc(operand_2, @r[rn], set_conditions))
    when 0b1000 # TST
      set_neg_and_zero_flags(@r[rn] & operand_2)
      @cpsr.carry = barrel_shifter_carry_out
    when 0b1001 # TEQ
      set_neg_and_zero_flags(@r[rn] ^ operand_2)
      @cpsr.carry = barrel_shifter_carry_out
    when 0b1010 # CMP
      sub(@r[rn], operand_2, set_conditions)
    when 0b1011 # CMN
      add(@r[rn], operand_2, set_conditions)
    when 0b1100 # ORR
      set_reg(rd, @r[rn] | operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    when 0b1101 # MOV
      set_reg(rd, operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    when 0b1110 # BIC
      set_reg(rd, @r[rn] & ~operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    when 0b1111 # MVN
      set_reg(rd, ~operand_2)
      if set_conditions
        set_neg_and_zero_flags(@r[rd])
        @cpsr.carry = barrel_shifter_carry_out
      end
    else raise "Unimplemented execution of data processing opcode: #{hex_str opcode}"
    end
    @r[15] &-= 4 if pc_reads_12_ahead
    if rd == 15 && set_conditions
      # puts "returning"
      old_spsr = @spsr.value
      new_mode = CPU::Mode.from_value(@spsr.mode)
      switch_mode new_mode
      @cpsr.value = old_spsr
      @spsr.value = new_mode.bank == 0 ? @cpsr.value : @spsr_banks[new_mode.bank]
      # puts "                                cpsr:#{hex_str @cpsr.value}, spsr:#{hex_str @spsr.value}"
    end
  end
end
