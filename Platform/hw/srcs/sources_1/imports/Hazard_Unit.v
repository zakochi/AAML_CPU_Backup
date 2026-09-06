// Hazard_Unit.v
module Hazard_Unit(
    input  wire inst_rdy_i,  
    input  wire EX_start,        
    input  wire EX_done,         
    input  wire br_taken,        
    input  wire fetch_invalid_i, 

    output wire req_inst_o,      
    output wire redirect_valid_o,

    output wire ID_en,
    output wire ID_clear,
    output wire EX_en,
    output wire EX_clear,
    output wire WB_en,
    output wire WB_clear
);
    wire stall = EX_start && !EX_done;
    assign req_inst_o = inst_rdy_i && !stall;


    assign ID_en = !stall; 
    assign EX_en = !stall; 
    assign WB_en = 1'b1;   

    wire flush_req = br_taken || fetch_invalid_i;
    
    assign redirect_valid_o = flush_req;

    assign ID_clear = flush_req; 
    
    assign EX_clear = 1'b0;      
    
    assign WB_clear = stall;

endmodule