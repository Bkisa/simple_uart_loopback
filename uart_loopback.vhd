-- author: Furkan Cayci, 2018
-- description: uart top module with axi stream interface

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_loopback is
    generic (
        CLKFREQ    : integer := 125E6; -- 125 Mhz clock
        BAUDRATE   : integer := 19200;
        DATA_WIDTH : integer := 8;
        PARITY     : string  := "NONE"; -- NONE, EVEN, ODD
        STOP_WIDTH : integer := 1
    );
    port (
        clk     : in  std_logic;
        -- external interface signals
        i_rxData     : in  std_logic;
        o_txData     : out std_logic;
        o_rxLed      : out std_logic;
        o_txLed      : out std_logic
    );
end uart_loopback;

architecture rtl of uart_loopback is


    signal s_paralel_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s_uartData_ready : std_logic;
    signal s_uartData_valid : std_logic;

    component uart_rx is
    generic (
        CLKFREQ    : integer := 125E6;
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
    end component;

    component uart_tx is
    generic (
        CLKFREQ    : integer := 125E6;
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
    end component;

begin

    rx0 : entity work.uart_rx(rtl)
        generic map (CLKFREQ=>CLKFREQ, BAUDRATE=>BAUDRATE,
                     DATA_WIDTH=>DATA_WIDTH, PARITY=>PARITY, STOP_WIDTH=>STOP_WIDTH)
        port map (clk=>clk, i_rxData=>i_rxData, i_data_ready=> s_uartData_ready,
                  o_rxData => s_paralel_data, o_rxData_valid => s_uartData_valid, o_rxLed => o_rxLed);

    tx0 : entity work.uart_tx(rtl)
        generic map (CLKFREQ=>CLKFREQ, BAUDRATE=>BAUDRATE,
                     DATA_WIDTH=>DATA_WIDTH, PARITY=>PARITY, STOP_WIDTH=>STOP_WIDTH)
        port map (clk=>clk, o_txData=>o_txData, i_txData_valid => s_uartData_valid,
                  i_txData => s_paralel_data, o_txData_ready => s_uartData_ready, o_txLed => o_txLed);

end rtl;