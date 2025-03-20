--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	
	signal w_L : std_logic := '0';
	signal w_R : std_logic := '0';
	signal w_reset : std_logic := '0';
	signal w_clk : std_logic := '0';
	
	--output: 
	signal left_leds : std_logic_vector(2 downto 0) := "000"; --left output 
	signal right_leds : std_logic_vector(2 downto 0) := "000"; --right output 

	
	-- constants
	constant k_clk_period : time := 10 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map(
        i_clk => w_clk,
        i_reset => w_reset,
        i_left => w_L,
        i_right => w_R,
        o_lights_L => left_leds,    
        o_lights_R => right_leds 	
	);
	
	
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
	begin
		w_clk <= '0';
        wait for k_clk_period/2;
		w_clk <= '1';
		wait for k_clk_period/2;
	end process;
    
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	
	sim_proc: process
	begin 
	    
	    wait for k_clk_period; 
		-- test left lights. Turn the left input on and watch the leds to light up in sequence and go back to state 000
		w_L <= '1'; 
		wait for k_clk_period;
		  assert left_leds = "001" report "bad left stage 1" severity failure;
	    wait for k_clk_period;
	      assert left_leds = "011" report "bad left stage 2" severity failure; 
	    wait for k_clk_period;
	      assert left_leds = "111" report "bad left stage 3" severity failure; 
	      assert right_leds = "000" report "why are any of the right lights on" severity failure;
	    wait for k_clk_period; 
	    -- test right lights. Turn left off, right on, and watch them blink in sequence and go back to state 000
	    w_R <= '1'; w_L <= '0'; 
	    wait for k_clk_period;
	      assert right_leds = "001" report "bad right stage 1" severity failure;
	    wait for k_clk_period;
	      assert right_leds = "011" report "bad right stage 2" severity failure; 
	    wait for k_clk_period;
	      assert right_leds = "111" report "bad right stage 3" severity failure; 
	      assert left_leds = "000" report "why are any of the left lights on" severity failure;
	      
	    -- test blink lights. turn both signals and wait. 
	    wait for k_clk_period; 

	    w_R <= '1'; w_L <= '1'; wait for k_clk_period;
	       assert right_leds = "111" report "right not blinking on" severity failure;
	       assert left_leds = "111" report "left not blinking on" severity failure; 
	    wait for k_clk_period;
	       assert right_leds = "000" report "right not blinking off" severity failure;
	       assert left_leds = "000" report "right not blinking off" severity failure; 
	       
	    wait for k_clk_period;
	    wait for k_clk_period;
	    wait for k_clk_period;
	    
  	    --check reset. When reset is 1, we should stay at 000. when reset is 0 again, we shoudl go back to blinking because left and right are still on. 
	    w_reset <= '0';
		wait for k_clk_period*1;
		w_reset <= '1';
		wait for k_clk_period*1;
		  assert left_leds = "000" report "bad reset left" severity failure;	
		  assert right_leds = "000" report "bad reset right" severity failure;	
		w_reset <= '0';
		  wait for k_clk_period*1;

	       wait;
	-----------------------------------------------------	
end process;

end; 
