//  CLI - Command line parameter
string                      version_t;
string                      speedmode_t;
string                      dma_mode_t;
string                      addr_mode_t;

//  TB testbench - BF bit field initialization parameter values
logic                       version_c;
logic   [3:0]               speedmode_c;
logic   [2:0]               dma_mode_c;
logic                       addr_mode_c;

task    hc_version_select;
        if ($value$plusarge("version=%s",version_t)) begin
            message = $sprintf("HC version= %s",version_t);
            if      ( version_t == "3.0" )) begin version_c = 1'b0; end
            else if ( version_t == "4.0" )) begin version_c = 1'b1; end
            else if ( version_t == "5.0" )) begin
                 $display("%5s%s you are rediculous\n","",message);
                 $finish();
                 end
            else begin
                 $display("%5s%s NOT defined --> exit test\n","",message)
                 $finish();
            end
            $display("%5s%s :: %b",message,version_c);
        end
endtask:hc_version_select


task    speedmode_select;
        if ($value$plusarge("mode=%s",speedmode_t)) begin
            message = $sprintf("Speed mode= %s",speedmode_t);
            if      ( speedmode_t == "SDR12"  )) begin speedmode_c = 3'b000; end
            else if ( speedmode_t == "SDR25"  )) begin speedmode_c = 3'b001; end
            else if ( speedmode_t == "SDR50"  )) begin speedmode_c = 3'b010; end
            else if ( speedmode_t == "SDR104" )) begin speedmode_c = 3'b011; end
            else if ( speedmode_t == "DDR50"  )) begin speedmode_c = 3'b100; end
            else if ( speedmode_t == "WARBSPEED" )) begin
                 $display("%5s%s you are rediculous\n","",message);
                 $finish();
                 end
            else begin
                 $display("%5s%s NOT defined --> exit test\n","",message)
                 $finish();
            end
            $display("%5s%s :: %b",message,speedmode_c);
        end
endtask:speedmode_select


task    dma_mode_select;
        if ($value$plusarge("dma=%s",dma_mode_t)) begin
            message = $sprintf("DMA mode= %s",dma_mode_t);
            if      ( dma_mode_t == "SDMA"     )) begin dma_mode_c = 2'b00; end
            else if ( dma_mode_t == "notused"  )) begin dma_mode_c = 2'b01; end
            else if ( dma_mode_t == "ADMA2"    )) begin dma_mode_c = 2'b10; end
            else if ( dma_mode_t == "reserved" )) begin dma_mode_c = 2'b11; end
            else if ( dma_mode_t == "DMA" )) begin
                 $display("%5s%s you are rediculous\n","",message);
                 $finish();
                 end
            else begin
                 $display("%5s%s NOT defined --> exit test\n","",message)
                 $finish();
            end
            $display("%5s%s :: %b",message,dma_mode_c);
        end
endtask:dma_mode_select


task    dma_address_mode_select ;
        if ($value$plusarge("addrm=%s",addr_mode_t)) begin
            message = $sprintf("DMA address mode= %s",addr_mode_t);
            if      ( addr_mode_t == "32bit" )) begin addr_mode_c = 1'b0; end
            else if ( addr_mode_t == "64bit" )) begin addr_mode_c = 1'b1; end
            else if ( addr_mode_t == "32" )) begin
                 $display("%5s%s you are rediculous\n","",message);
                 $finish();
                 end
            else begin
                 $display("%5s%s NOT defined --> exit test\n","",message)
                 $finish();
            end
            $display("%5s%s :: %b",message,addr_mode_c);
        end
endtask:dma_address_mode_select 


task    dma_address_mode_select ;
        hc_version_select;
        speedmode_select;
        dma_mode_select;
        dma_address_mode_select ;
endtask:dma_address_mode_select 
