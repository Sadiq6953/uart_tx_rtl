library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
  Port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    tx_start  : in  std_logic;
    tx_data   : in  std_logic_vector(7 downto 0);
    tx_out    : out std_logic;
    tx_busy   : out std_logic
  );
end uart_tx;

architecture rtl of uart_tx is

  type state_type is (IDLE, START, DATA, STOP);
  signal state        : state_type := IDLE;

  signal baud_cnt     : integer := 0;
  signal baud_tick    : std_logic := '0';
  constant BAUD_DIV   : integer := 434; -- for example, 50 MHz / 115200 ≈ 434

  signal bit_index    : integer range 0 to 7 := 0;
  signal tx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_reg       : std_logic := '1';

begin

  -- Baud rate generator
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        baud_cnt  <= 0;
        baud_tick <= '0';
      elsif state /= IDLE then
        if baud_cnt = BAUD_DIV then
          baud_cnt  <= 0;
          baud_tick <= '1';
        else
          baud_cnt  <= baud_cnt + 1;
          baud_tick <= '0';
        end if;
      else
        baud_cnt  <= 0;
        baud_tick <= '0';
      end if;
    end if;
  end process;

  -- UART FSM
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state        <= IDLE;
        tx_shift_reg <= (others => '0');
        bit_index    <= 0;
        tx_reg       <= '1';
      else
        case state is

          when IDLE =>
            if tx_start = '1' then
              tx_shift_reg <= tx_data;
              state        <= START;
              tx_reg       <= '0';  -- Start bit
            end if;

          when START =>
            if baud_tick = '1' then
              state <= DATA;
              bit_index <= 0;
            end if;

          when DATA =>
            if baud_tick = '1' then
              tx_reg <= tx_shift_reg(bit_index);
              if bit_index = 7 then
                state <= STOP;
              else
                bit_index <= bit_index + 1;
              end if;
            end if;

          when STOP =>
            if baud_tick = '1' then
              tx_reg <= '1';  -- Stop bit
              state <= IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

  tx_out  <= tx_reg;
  tx_busy <= '1' when state /= IDLE else '0';

end rtl;

