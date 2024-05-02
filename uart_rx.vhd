-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Adam Veselý (xvesela00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;                        -- signal clock
        RST      : in std_logic;                        -- reset clock
        DIN      : in std_logic;                        -- input bit
        DOUT     : out std_logic_vector(7 downto 0);    -- output (8 bits)
        DOUT_VLD : out std_logic                        -- data validation
    );
end entity;

architecture behavioral of UART_RX is
    signal clk_cnt        : std_logic_vector(4 downto 0) := "00001";   -- clock counter
    signal clk_active     : std_logic := '0';                          -- check if 'clock counter' is active
    signal bit_cnt              : std_logic_vector(3 downto 0) := "0000";    -- loaded bits counter 
    signal data_recieve  : std_logic := '0';                          -- check if 'reading data' is active
    signal data_validate : std_logic := '0';                          -- check if 'validating data' is active

begin
    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK => CLK,
        RST => RST,
        DIN => DIN,
        CLK_CNT => clk_cnt,
        CLK_ACTIVE => clk_active,
        BIT_CNT => bit_cnt,
        DATA_RECIEVE => data_recieve,
        DATA_VALIDATE => data_validate
    );

    -- PROCESS
    process (CLK) begin
        
        -- RESET
        if RST = '1' then
            DOUT_VLD <= '0';          -- initialize DOUT_VLD to 0
            DOUT <= (others => '0');  -- reset DOUT to 0
            clk_cnt <= "00001";       -- reset clock counter to 1
            bit_cnt <= "0000";        -- reset bit counter to 0

        -- RISING EDGE
        elsif rising_edge(CLK) then

            if clk_active = '0' then -- clock counter inactive
                clk_cnt <= "00001"; -- reset clock counter to 1
            else  -- clock counter active
                clk_cnt <= clk_cnt + 1; -- clk_cnt++
            end if;

            DOUT_VLD <= '0'; -- set DOUT_VLD to 0

            if bit_cnt = "1000" then -- we have read all the bits
                if data_validate = '1' then -- we have recieved a stop bit
                    bit_cnt <= "0000"; -- reset bit counter to 0
                    DOUT_VLD <= '1'; -- data validated correctly
                end if;
            end if;

            if data_recieve = '1' then -- we are recieving data
                if clk_cnt >= "10000" then -- clock counter is >= 16
                    clk_cnt <= "00001"; -- reset clock counter back to 1

                    -- LOAD BITS
                    case bit_cnt is
                        when "0000" => 
                            DOUT(0) <= DIN;
                            bit_cnt <= "0001";
                        when "0001" => 
                            DOUT(1) <= DIN;
                            bit_cnt <= "0010";
                        when "0010" => 
                            DOUT(2) <= DIN;
                            bit_cnt <= "0011";
                        when "0011" => 
                            DOUT(3) <= DIN;
                            bit_cnt <= "0100";
                        when "0100" => 
                            DOUT(4) <= DIN;
                            bit_cnt <= "0101";
                        when "0101" => 
                            DOUT(5) <= DIN;
                            bit_cnt <= "0110";
                        when "0110" => 
                            DOUT(6) <= DIN;
                            bit_cnt <= "0111";
                        when "0111" => 
                            DOUT(7) <= DIN;
                            bit_cnt <= "1000";
                        when others => null;
                    end case;

                end if;
            end if;
        end if;
    end process; 
end architecture;
