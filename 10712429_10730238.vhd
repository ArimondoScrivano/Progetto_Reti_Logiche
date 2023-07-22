library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;

entity  project_reti_logiche is
port(
 i_clk : IN STD_LOGIC;
           i_rst : IN STD_LOGIC;
           i_start : IN STD_LOGIC;
           i_w : IN STD_LOGIC;

           o_z0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           o_z1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           o_z2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           o_z3 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
           o_done : OUT STD_LOGIC;

           o_mem_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
           i_mem_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
           o_mem_we : OUT STD_LOGIC;
           o_mem_en : OUT STD_LOGIC
);
end  project_reti_logiche;

architecture Behavioral of project_reti_logiche is

--DESCRIZIONE DELLA FSM
type state_type is (S0, S1, S2,S3,S4,S5);
signal next_state, current_state: state_type;

--segnali per la gestione dei 4 registri
signal enable_reg: std_logic_vector(3 downto 0);
signal r_0: std_logic_vector(7 downto 0);
signal r_1: std_logic_vector(7 downto 0);
signal r_2: std_logic_vector(7 downto 0);
signal r_3:std_logic_vector(7 downto 0);

--Segnali pr il add-receiver
signal add_receiver_rst: std_logic;
signal raw_address: std_logic_vector(17 downto 0);
signal fill_address: integer;
--segnali per il converter
signal conv_add_rst: std_logic;
signal conv_add_start: std_logic;
signal add_out: std_logic_vector(1 downto 0);

--segnali per il selettore dell'uscita
signal s_display: std_logic;

--segnali per il decoder 
signal start_decoding: std_logic;


begin
o_mem_en<='1';
o_mem_we<='0';


--PROCESSO + REGISTRO DI RICEZIONE INDIRIZZO USCITA
ADD_RECEIVER: process(i_rst,add_receiver_rst, i_clk)
begin
if add_receiver_rst='1' or i_rst='1' then
    raw_address<="000000000000000000";
    fill_address<= 18;
elsif i_clk'event and i_clk='1' then
if i_start='1' then
        raw_address<=raw_address(16 downto 0)& i_w;
        fill_address<= fill_address-1;
end if;
end if;
end process;

CONV_ADD: process(i_rst, i_clk,conv_add_rst)
begin
if i_rst='1' or conv_add_rst='1' then
o_mem_addr<="0000000000000000";
add_out<="00";
else
if rising_edge(i_clk) then
if conv_add_start<= '1' then

case fill_address is
when 16=> 
    o_mem_addr<="0000000000000000";
    add_out<= raw_address(1 downto 0);
 when 15=>
    o_mem_addr<="000000000000000"& raw_address(0);
    add_out<= raw_address(2 downto 1);
  when 14=>
    o_mem_addr<="00000000000000" & raw_address(1 downto 0);
    add_out<= raw_address(3 downto 2);
   when 13=>
    o_mem_addr<="0000000000000" & raw_address(2 downto 0);
    add_out<= raw_address(4 downto 3);   
    when 12=>
    o_mem_addr<="000000000000" & raw_address(3 downto 0);
    add_out<= raw_address(5 downto 4);
     when 11=>
    o_mem_addr<="00000000000" & raw_address(4 downto 0);
    add_out<= raw_address(6 downto 5);
      when 10=>
    o_mem_addr<="0000000000" & raw_address(5 downto 0);
    add_out<= raw_address(7 downto 6);
       when 9=>
    o_mem_addr<="000000000" & raw_address(6 downto 0);
    add_out<= raw_address(8 downto 7);
        when 8=>
    o_mem_addr<="00000000" & raw_address(7 downto 0);
    add_out<= raw_address(9 downto 8);
         when 7=>
    o_mem_addr<="0000000" & raw_address(8 downto 0);
    add_out<= raw_address(10 downto 9);
          when 6=>
    o_mem_addr<="000000" & raw_address(9 downto 0);
    add_out<= raw_address(11 downto 10);
           when 5=>
    o_mem_addr<="00000" & raw_address(10 downto 0);
    add_out<= raw_address(12 downto 11);
            when 4=>
    o_mem_addr<="0000" & raw_address(11 downto 0);
    add_out<= raw_address(13 downto 12);
             when 3=>
    o_mem_addr<="000" & raw_address(12 downto 0);
    add_out<= raw_address(14 downto 13);
              when 2=>
    o_mem_addr<="00" & raw_address(13 downto 0);
    add_out<= raw_address(15 downto 14);
               when 1=>
    o_mem_addr<="0" & raw_address(14 downto 0);
    add_out<= raw_address(16 downto 15);
                when 0=>
    o_mem_addr<= raw_address(15 downto 0);
    add_out<= raw_address(17 downto 16);
                 when others=>
    o_mem_addr<="0000000000000000";
    add_out<="00";
end case;
end if;
end if;
end if;
end process;

--PROCESSO + DECODER PER LA GESTIONE DEGLI ENABLE SUI REGISTRI

DECODER_ENABLE: process(start_decoding,i_rst)
begin 
if i_rst='1' then
    enable_reg<="0000";
elsif start_decoding='1' then
        case add_out is
            when "00"=> enable_reg<="0001";
            when "01"=> enable_reg<="0010";
            when "10"=> enable_reg<="0100";
            when "11"=> enable_reg<="1000";
            when others=> enable_reg<= "0000";
        end case;
    else
        enable_reg<="0000";
    end if;
end process;


--PROCESSO SELETTORE USCITA
SEL_USCITA: process(i_rst,s_display)
begin
if i_rst='1' then
    o_z0<="00000000";
    o_z1<="00000000";
    o_z2<="00000000";
    o_z3<="00000000";
    elsif s_display='1' then
        o_z0<= r_0;
        o_z1<= r_1;
        o_z2<= r_2;
        o_z3<= r_3;
    else
        o_z0<="00000000";
        o_z1<="00000000";
        o_z2<="00000000";
        o_z3<="00000000";    
    end if;
end process;


--PROCESSI DEDICATI ALLA FSM--

--PROCESSO DI RESET DELLA MACCHINA E DI AGGIORNAMENTO STATI
RESET_FSM:  process(i_rst, i_clk)
begin
if i_rst='1' then
    current_state<= S0;
elsif rising_edge(i_clk) then
    current_state<= next_state;
end if;
end process;

--PROCESSO PER LA GESTIONE DEL NEXT_STATE


NEXT_STATE_MENAGER:process(current_state,i_start)
begin
next_state<= current_state;
case current_state is
WHEN S0=>
    if i_start ='1' then
        next_state<= S1;
    end if;
WHEN S1=>
    if i_start='1' then
        next_state<= S1;
    else
        next_state<= S2;
    end if;
WHEN S2 =>
next_state<= S3;
    
WHEN S3 =>
next_state<= S4;
WHEN S4=>
    next_state<= S5;
WHEN S5=>
    next_state<= S0;

end case;
end process;

--PROCESSO PER LA GESTIONE DEI SEGNALI DI AVANZAMENTO STATO  DELLA FSM

STATE_MANAGER: process(current_state)
begin
 o_done<='0';
 add_receiver_rst<='0';
 conv_add_rst<='0';
 conv_add_start<='0';
 s_display<='0';
 start_decoding<='0';
case current_state is
WHEN S0=>
--stato di reset--
WHEN S1=>
-- stiamo ricevendo l'indirizzo--

WHEN S2=> 
conv_add_start<='1';
  --stiamo convertendo l'indirizzo--
WHEN S3=>

 
WHEN S4=>
    start_decoding<='1';
WHEN S5=>
  s_display<='1';
  o_done<='1';
  add_receiver_rst<='1';
  conv_add_rst<='1';
end case;
end process;


REGISTRO_0: process(i_rst,i_clk)

begin
    if i_rst='1' then
        r_0<= "00000000";
    elsif i_clk'event and i_clk='1' then
        if enable_reg(0)='1' then
             r_0<= i_mem_data;
         end if;    
    end if;
end process;

REGISTRO_1: process(i_rst,i_clk)

begin
    if i_rst='1' then
        r_1<= "00000000";
    elsif i_clk'event and i_clk='1' then
        if enable_reg(1)='1' then
             r_1<= i_mem_data;
         end if;    
    end if;
end process;

REGISTRO_2: process(i_rst,i_clk)

begin
    if i_rst='1' then
        r_2<= "00000000";
    elsif i_clk'event and i_clk='1' then
        if enable_reg(2)='1' then
             r_2<= i_mem_data;
         end if;    
    end if;
end process;

REGISTRO_3: process(i_rst,i_clk)

begin
    if i_rst='1' then
        r_3<= "00000000";
    elsif i_clk'event and i_clk='1' then
        if enable_reg(3)='1' then
             r_3<= i_mem_data;
         end if;    
    end if;
end process;


end Behavioral;
