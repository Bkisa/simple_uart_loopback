-- author: Furkan Cayci, 2018
-- description: uart transmit interface

library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        CLKFREQ    : integer;
        BAUDRATE   : integer;
        DATA_WIDTH : integer := 8;
        PARITY     : string  := "NONE"; -- NONE, EVEN, ODD
        STOP_WIDTH : integer := 1
    );
    port (
        clk : in  std_logic;   
        o_txData : out std_logic;  
        i_txData_valid  : in  std_logic;
        i_txData        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        o_txData_ready  : out std_logic;
        o_txLed         : out std_logic
    );
end uart_tx;

architecture rtl of uart_tx is
    signal tready : std_logic := '0';
    constant M : integer := CLKFREQ / BAUDRATE;
begin

    o_txData_ready <= tready;

    main: process(clk) is
        type state_type is (st_idle, st_start, st_data, st_parity, st_stop);
        variable state : state_type := st_idle;
        variable txbuf : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        variable bitcount : integer range 0 to DATA_WIDTH-1 := 0;
        variable clkcount : integer range 0 to M-1 := 0;
    begin
        if rising_edge(clk) then
            o_txData <= '1';
            tready <= '0';

            case state is
                when st_idle =>
                    tready <= '1';
                    o_txLed <= '0';
                    if i_txData_valid = '1' then
                        txbuf := i_txData;
                        state := st_start;
                    end if;

                when st_start =>
                    o_txData <= '0';
                    if clkcount = M-1 then
                        clkcount := 0;
                        state := st_data;
                    else
                        clkcount := clkcount + 1;
                    end if;

                when st_data =>
                    o_txLed <= '0';
                    o_txData <= txbuf(bitcount);
                    if clkcount = M-1 then
                        clkcount := 0;

                        if bitcount = DATA_WIDTH-1 then
                            o_txLed <= '0';
                            bitcount := 0;
                            if PARITY = "NONE" then
                                state := st_stop;
                            else
                                state := st_parity;
                            end if;
                        else
                            o_txLed <= '1';
                            bitcount := bitcount + 1;
                        end if;
                    else
                        o_txLed <= '1';
                        clkcount := clkcount + 1;
                    end if;

                when st_parity =>
                    o_txLed <= '0';
                    state := st_stop;

                when st_stop =>
                    o_txData <= '1';
                    o_txLed <= '0';
                    if clkcount = M-1 then
                        clkcount := 0;
                        if bitcount = STOP_WIDTH-1 then
                            bitcount := 0;
                            state := st_idle;
                        else
                            bitcount := bitcount + 1;
                        end if;
                    else
                        clkcount := clkcount + 1;
                    end if;
            end case;
         end if;
    end process;

end rtl;