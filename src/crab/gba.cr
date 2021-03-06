require "./types"
require "./reg"
require "./util"
require "./scheduler"
require "./cartridge"
require "./flash"
require "./mmio"
require "./timer"
require "./keypad"
require "./bus"
require "./interrupts"
require "./cpu"
require "./display"
require "./ppu"
require "./apu"
require "./dma"
require "./debugger"

class GBA
  getter! scheduler : Scheduler
  getter! cartridge : Cartridge
  getter! flash : Flash
  getter! mmio : MMIO
  getter! timer : Timer
  getter! keypad : Keypad
  getter! bus : Bus
  getter! interrupts : Interrupts
  getter! cpu : CPU
  getter! display : Display
  getter! ppu : PPU
  getter! apu : APU
  getter! dma : DMA
  getter! debugger : Debugger

  def initialize(@bios_path : String, rom_path : String)
    @scheduler = Scheduler.new
    @cartridge = Cartridge.new rom_path
    @flash = Flash.new rom_path
    handle_events
    handle_saves

    SDL.init(SDL::Init::VIDEO | SDL::Init::AUDIO | SDL::Init::JOYSTICK)
    LibSDL.joystick_open 0
    at_exit { SDL.quit }
  end

  def post_init : Nil
    @mmio = MMIO.new self
    @timer = Timer.new self
    @keypad = Keypad.new self
    @bus = Bus.new self, @bios_path
    @interrupts = Interrupts.new self
    @cpu = CPU.new self
    @display = Display.new
    @ppu = PPU.new self
    @apu = APU.new self
    @dma = DMA.new self
    @debugger = Debugger.new self
  end

  def handle_events : Nil
    scheduler.schedule 280896, ->handle_events
    while event = SDL::Event.poll
      case event
      when SDL::Event::Quit then exit 0
      when SDL::Event::Keyboard,
           SDL::Event::JoyHat,
           SDL::Event::JoyButton then keypad.handle_keypad_event event
      else nil
      end
    end
  end

  def handle_saves : Nil
    scheduler.schedule 280896, ->handle_saves
    flash.write_save
  end

  def run : Nil
    loop do
      {% if flag? :debugger %} debugger.check_debug {% end %}
      cpu.tick
    end
  end

  def tick(cycles : Int) : Nil
    scheduler.tick cycles
  end
end
