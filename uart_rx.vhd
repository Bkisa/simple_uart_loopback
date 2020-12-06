-- author: Furkan Cayci, 2018
-- description: uart receive interface

library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
    generic (
        CLKFREQ    : integer;
        BAUDRATE   : integer;
        DATA_WIDTH : integer := 8;
        PARITY     : string  := "NONE"; -- NONE, EVEN, ODD
        STOP_WIDTH : integer := 1
    );
    port (
        clk : in  std_logic;
        -- external interface signals
        i_rxData : in  std_logic;
        -- axi stream interface
        i_data_ready  : in  std_logic;
        o_rxData      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        o_rxData_valid: out std_logic;
        o_rxLed       : out std_logic
    );
end uart_rx;

architecture rtl of uart_rx is
    signal tvalid : std_logic := '0';
    signal tdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    constant M : integer := CLKFREQ / BAUDRATE; -- clock cycles per bit
begin

    o_rxData_valid <= tvalid;
    o_rxData <= tdata;

    main: process(clk) is
        type state_type is (st_idle, st_data, st_parity, st_stop);
        variable state : state_type := st_idle;
        variable rxbuf : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
        variable bitcount : integer range 0 to DATA_WIDTH-1 := 0;
        variable clkcount : integer range 0 to M-1 := 0;
    begin
        if rising_edge(clk) then
            if i_data_ready = '1' then
                tvalid <= '0';
            end if;

            case state is
                when st_idle =>
                    o_rxLed <= '0';
                    if i_rxData = '0' then
                        if clkcount = M/2 - 1 then
                            clkcount := 0;
                            state := st_data;
                        else
                            clkcount := clkcount + 1;
                        end if;
                    else
                        clkcount := 0;
                    end if;

                when st_data =>
                    o_rxLed <= '0';
                    if clkcount = M-1 then
                        clkcount := 0;
                        rxbuf := i_rxData & rxbuf(DATA_WIDTH-1 downto 1);
                        if bitcount = DATA_WIDTH-1 then
                            o_rxLed <= '0';
                            bitcount := 0;
                            if PARITY = "NONE" then
                                state := st_stop;
                            else
                                state := st_parity;
                            end if;
                        else
                            o_rxLed <= '1';
                            bitcount := bitcount + 1;
                        end if;
                    else
                        o_rxLed <= '1';
                        clkcount := clkcount + 1;
                    end if;

                when st_parity =>
                    o_rxLed <= '0';
                    state := st_stop;

                when st_stop =>
                    if clkcount = M-1 then
                        clkcount := 0;
                        o_rxLed <= '0';
                        state := st_idle;
                        tvalid <= '1';
                        tdata <= rxbuf;
                    else
                        clkcount := clkcount + 1;
                    end if;

            end case;
         end if;
    end process;

end rtl;