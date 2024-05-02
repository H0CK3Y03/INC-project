-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Adam Veselý (xvesela00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity UART_RX_FSM is
    port(
       CLK                   : in std_logic;                     -- signal clock
       RST                   : in std_logic;                     -- reset clock
       DIN                   : in std_logic;                     -- input bit
       CLK_CNT         : in std_logic_vector(4 downto 0);        -- clock counter
       CLK_ACTIVE      : out std_logic;                          -- check if clock counter is active
       BIT_CNT               : in std_logic_vector(3 downto 0);  -- bit counter
       DATA_RECIEVE   : out std_logic;                    -- check if reading data is active  
       DATA_VALIDATE  : out std_logic                     -- check if validating data is active
    );
end entity;

architecture behavioral of UART_RX_FSM is
    type fsm_states is (NOT_ACTIVE, WAIT_FOR_FIRST_BIT, READ_DATA, WAIT_FOR_STOP_BIT, VALIDATE_DATA);
    signal current_state : fsm_states := NOT_ACTIVE;

begin

    -- ACTIVATING PORTS
    CLK_ACTIVE <= '0' when current_state = NOT_ACTIVE or current_state = VALIDATE_DATA else '1'; -- counting clock only in WAIT_FOR_FIRST_BIT, READ_DATA and WAIT_FOR_STOP_BIT states
    DATA_VALIDATE <= '1' when current_state = VALIDATE_DATA else '0'; -- becomes 1 when we start validating data
    DATA_RECIEVE <= '1' when current_state = READ_DATA else '0'; -- becomes 1 when we start reading bits

    -- PROCESS
    process(CLK) begin

        -- RESET
        if RST = '1' then
            current_state <= NOT_ACTIVE;
            
        -- RISING EDGE
        elsif rising_edge(CLK) then

            -- HANDLE STATES
            case current_state is
                when NOT_ACTIVE => 
                    if DIN = '0' then -- 0 is the start bit
                        current_state <= WAIT_FOR_FIRST_BIT;
                    end if;
                when WAIT_FOR_FIRST_BIT =>
                    if CLK_CNT = "10111" then -- wait 23 clock cycles
                        current_state <= READ_DATA;
                    end if;
                when READ_DATA =>
                    if BIT_CNT = "1000" then -- read 8 bits of data
                        current_state <= WAIT_FOR_STOP_BIT; 
                    end if;
                when WAIT_FOR_STOP_BIT =>
                    if DIN = '1' then -- 1 is a stop bit
                        if CLK_CNT = "01111" then -- validate data mid-stopbit
                            current_state <= VALIDATE_DATA;
                        end if;
                    end if;
                when VALIDATE_DATA =>
                    current_state <= NOT_ACTIVE;
                when others => null; -- default case
            end case;

        end if;
    end process;
end architecture;
