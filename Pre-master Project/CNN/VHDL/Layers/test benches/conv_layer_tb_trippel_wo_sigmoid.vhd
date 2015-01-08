library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_layer_tb_trippel_wo_sig IS
	generic (
		IMG_DIM 			: integer := 6;
		KERNEL_DIM 		: integer := 3;
		MAX_POOL_DIM 	: integer := 2;
		INT_WIDTH 		: integer := 8;
		FRAC_WIDTH 		: integer := 8
	);
END conv_layer_tb_trippel_wo_sig;

ARCHITECTURE behavior OF conv_layer_tb_trippel_wo_sig IS 

	component convolution_layer is
		generic (
			IMG_DIM 			: integer := IMG_DIM;
			KERNEL_DIM 		: integer := KERNEL_DIM;
			MAX_POOL_DIM 	: integer := MAX_POOL_DIM;
			INT_WIDTH 		: integer := INT_WIDTH;
			FRAC_WIDTH 		: integer := FRAC_WIDTH
		);
		
		port ( 
			clk 			: in std_logic;
			reset			: in std_logic;
			conv_en		: in std_logic;
			first_layer	: in std_logic;
			weight_we	: in std_logic;
			weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_valid	: out std_logic;
			pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			dummy_bias	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	signal clk 				: std_logic := '0';
	signal reset			: std_logic := '0';
	signal conv_en			: std_logic := '0';
	signal first_layer	: std_logic := '0';
	signal weight_we		: std_logic := '0';
	signal weight_data	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_in		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_valid	: std_logic := '0';
	signal pixel_out 		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal dummy_bias		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	
	constant clk_period : time := 1 ns;
	
	-- INPUT/OUTPUT
	
	constant zero 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000000000000";
	constant one 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000100000000";
	constant two 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001000000000";
	constant three : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001100000000";
	constant four 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010000000000";
	constant five 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010100000000";
	
	constant result0 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1010110100000000";
	constant result1 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1100100000000000";
	constant result2 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1010001000000000";
	constant result3 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1111000100000000";
	
	constant OUTPUT_DIM : integer := (IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM;
	type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array ((KERNEL_DIM*KERNEL_DIM) downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type pooled_array is array ((OUTPUT_DIM*OUTPUT_DIM)-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal img1 : img_array := (
		two, zero, zero, five, two, one, 
		zero, four, two, three, zero, two, 
		one, zero, one, four, zero, zero, 
		two, three, one, zero, zero, five, 
		zero, one, two, four, five, five, 
		four, one, two, four, five, four
	);
	
	signal img2 : img_array := (
		two, five, three, three, four, one, 
		three, two, three, four, two, zero, 
		two, one, two, two, four, three, 
		one, four, one, three, three, one, 
		zero, one, four, five, one, four, 
		zero, zero, zero, zero, four, four
	);
	
	signal img3 : img_array := (
		three, five, three, three, three, four, 
		zero, one, one, five, one, three, 
		five, zero, five, zero, one, three, 
		three, four, one, five, two, five, 
		five, two, two, zero, four, two, 
		four, four, one, three, five, zero
	);
	
	signal kernel : kernel_array := (
		three,
		one, four, four,
		one, four, four,
		four, two, one
	);
	
	signal result : pooled_array := (
		result0, result1,
		result2, result3
	);
	
	
	
       
begin

	conv_layer : convolution_layer port map ( 
		clk 			=> clk,
		reset			=> reset,
		conv_en		=> conv_en,
		first_layer	=> first_layer,
		weight_we	=> weight_we,
		weight_data	=> weight_data,
		pixel_in		=> pixel_in,
		pixel_valid	=> pixel_valid,
		pixel_out 	=> pixel_out,
		dummy_bias	=> dummy_bias
	);

	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	create_input : process
	begin
		reset <= '1';
		
		wait for 100 ns; 
		first_layer <= '0';
		reset <= '0';
		weight_we <= '1';
		for i in 0 to (KERNEL_DIM*KERNEL_DIM) loop
			weight_data <= kernel(KERNEL_DIM*KERNEL_DIM-i);
			wait for clk_period;
		end loop;
		weight_we <= '0';
		wait for clk_period;
		
		conv_en <= '1';
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img1((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img2((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img3((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		conv_en <= '0';
		wait; 
	end process;
	
	assert_output : process
		
	begin
	
		wait for 100 ns;
		wait for 34*clk_period;
		assert pixel_out = result0
			report "Pixel_out was not equal to result0"
			severity error;
		
		wait for clk_period*2;
		assert pixel_out = result1
			report "Pixel_out was not equal to result1"
			severity error;
			
		wait for clk_period*10;
		assert pixel_out = result2
			report "Pixel_out was not equal to result2"
			severity error;
			
		wait for clk_period*2;
		assert pixel_out = result3
			report "Pixel_out was not equal to result3"
			severity error;
		
		wait;
	end process;
	

end;
