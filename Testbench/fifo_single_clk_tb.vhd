library ieee;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use IEEE.math_real.all;

entity fifo_single_clk_tb is 
generic (
		G_FIFO_8D	: natural := 8;
		G_FIFO_16D	: natural := 16;
		G_FIFO_64D	: natural := 64
	);
end entity;

architecture fifo_single_clk_tb_arc of fifo_single_clk_tb is


component fifo_single_clk
	generic(
		G_DEPTH :natural := 2
	);
	port(
		clk_i			:  in  std_logic;
		mrst_i			:  in  std_logic;
		sw_rst_i		:  in  std_logic;
		we_i			:  in  std_logic;
		data_i			:  in  std_logic_vector(7 downto 0);
		re_i			:  in  std_logic;
		data_o			:  out std_logic_vector(7 downto 0)
	);
end component;

	constant C_SYS_CLK_PERIOD		: time := 10 ns;
	-- ports for the instantiating the DUT components
	signal clk_i 		: std_logic := '0';
	signal sw_rst_i 	: std_logic := '0';
	signal mrst_i 		: std_logic := '0';
	signal we_i 		: std_logic := '0';
	signal re_8d_i 		: std_logic := '0';
	signal re_16d_i 	: std_logic := '0';
	signal re_64d_i 	: std_logic := '0';
	signal data_i		: std_logic_vector(7 downto 0) := (others => '0');
	signal data_8b_o 	: std_logic_vector(7 downto 0);
	signal data_16b_o 	: std_logic_vector(7 downto 0);
	signal data_64b_o 	: std_logic_vector(7 downto 0);

	-- Flags
	signal reset_done	: std_logic := '0';
	signal write_start	: std_logic := '0';
	signal read_start	: std_logic := '0';
	-- testbench pointer to keep track of
	signal rptr_8b		: natural := 0;
	signal rptr_16b		: natural := 0;
	signal rptr_64b		: natural := 0;
	signal wptr_8b		: natural := 0;
	signal wptr_16b		: natural := 0;
	signal wptr_64b		: natural := 0;
	-- temp signals
	signal data_int		: integer := 0;
	signal data_temp	: integer := 0;
	signal data_exp8 	: std_logic_vector(7 downto 0) := (others =>'0') := (others => '0');
	signal data_exp16 	: std_logic_vector(7 downto 0) := (others =>'0') := (others => '0');
	signal data_exp64 	: std_logic_vector(7 downto 0) := (others =>'0') := (others => '0');

begin

	-----------------------------
	-- Concurrent clock
	-- Freq: 100 MHz
	-- Period 10 ns
	-----------------------------
	clk_i <= not clk_i after C_SYS_CLK_PERIOD/2;


	-----------------------------
	-- One Time Master Reset
	-- time: 50 ns
	-----------------------------
	process 
	begin
		-- activate reset
		mrst_i <= '0';
		-- wait for minimum period
		wait for 50 ns;
		-- deactivate reset
		mrst_i <= '1';
		reset_done <= '1';
		-- end process 
		wait;
	end process;

	-----------------------------
	-- Instantiation of 
	-- FIFO with different
	-- depths
	-----------------------------

	DUT_DEPTH_8		: fifo_single_clk generic map (
													G_DEPTH => G_FIFO_8D
													)
									  port map	  (
									  				clk_i			=>clk_i,
													mrst_i			=>mrst_i,
													sw_rst_i		=>sw_rst_i,
													we_i			=>we_i,
													data_i			=>data_i,
													re_i			=>re_8d_i,
													data_o 			=>data_8b_o
									  			  );

	----------------------------
	-- Main Process
	-- intiates flags of 
	-- different tests to begin
	----------------------------
	main_tb: process 
	begin
		-- wait until reset for system is complete
		wait until reset_done = '1';
		-- begin test to fill FIFO
		write_start <= '1';
		-- wait until all fifos are full
		wait for C_SYS_CLK_PERIOD * 64;
		write_start <= '0';
		-- begin test to empty FIFO
		read_start <= '1';
		wait for C_SYS_CLK_PERIOD * 64;
		wait for C_SYS_CLK_PERIOD * 10;
		std.env.stop;
	end process;


	----------------------------
	-- Data Assignment for write 
	-- increments each clock 
	-- period
	----------------------------
	data_in_proc: process
	begin
		wait until write_start = '1';
		for i in 0 to 63 loop
			wait until rising_edge(clk_i);
			data_i <= std_logic_vector(to_unsigned(data_int, 8));
			data_int <= data_int + 1;
		end loop;
		wait;
	end process;

	----------------------------
	-- Data Assignment 
	-- calculates the expected
	-- value outputted from
	-- the FIFO
	----------------------------
	data_out_proc: process
	begin
		wait until read_start = '1';
		for i in 0 to 7 loop
			wait until rising_edge(clk_i);
			data_exp8 <= std_logic_vector(to_unsigned(data_temp, 8));
			data_temp <= data_temp + 1;
		end loop;

		for i in 0 to 15 loop
			wait until rising_edge(clk_i);
			data_exp16 <= std_logic_vector(to_unsigned(data_temp, 8));
			data_temp <= data_temp + 1;
		end loop;

		for i in 0 to 63 loop
			wait until rising_edge(clk_i);
			data_exp64 <= std_logic_vector(to_unsigned(data_temp, 8));
			data_temp <= data_temp + 1;
		end loop;
		wait;
	end process;

	----------------------------
	-- Self-Checking 
	-- check that the output 
	-- of the FIFO when read 
	----------------------------
	data_8b_out_self_check: process
	begin
		wait on data_8b_o;
		assert data_exp8 = data_8b_o;
			report "output of the FIFO was not the correct. Data may have been lost. (Depth 8)"
			severity error;
	end process;

	data_16b_out_self_check: process
	begin
		wait on data_16b_o;
		assert data_exp16 = data_16b_o;
			report "output of the FIFO was not the correct. Data may have been lost. (Depth 16)"
			severity error;
	end process;

	data_64b_out_self_check: process
	begin
		wait on data_64b_o;
		assert data_exp64 = data_64b_o;
			report "output of the FIFO was not the correct. Data may have been lost. (Depth 64)"
			severity error;
	end process;


--	DUT_DEPTH_16	: fifo_single_clk generic map (
--													G_DEPTH := G_FIFO_16D
--													)
--									  port map	  (
--									  				clk_i			=>clk_i,
--													mrst_i			=>mrst_i,
--													sw_rst_i		=>sw_rst_i,
--													we_i			=>we_i,
--													data_i			=>data_i,
--													re_i			=>re_16d_i,
--													data_o 			=>data_16b_o
--									  			  );
--
--	DUT_DEPTH_64	: fifo_single_clk generic map (
--													G_DEPTH := G_FIFO_64D
--													)
--									  port map	  (
--									  				clk_i			=>clk_i,
--													mrst_i			=>mrst_i,
--													sw_rst_i		=>sw_rst_i,
--													we_i			=>we_i,
--													data_i			=>data_i,
--													re_i			=>re_64d_i,
--													data_o 			=>data_64b_o
--									  			  );

	

end fifo_single_clk_tb_arc;