/**
    FBLAS: BLAS implementation for Intel FPGA
    Copyright (c) 2019 ETH-Zurich. All rights reserved.
    See LICENSE for license information.

    Reads a matrix of type TYPE_T from memory and push it
    into CHANNEL_MATRIX_B. This can be used for the systolic implementation of GEMM

    B is transposed

    CHANNEL_UNROLL reads are performed simultaneously.
    If needed, data is padded to tile sizes using zero elements.

*/
__kernel void READ_MATRIX_B(__global TYPE_T * restrict B, const unsigned int N, const unsigned int K, const unsigned int M, const unsigned int ldb)
{

    const int OuterBlocksN = 1 + (int)((N-1) / MTILE);
    const int OuterBlocksM = 1 + (int)((M-1) / MTILE);
    const int InnerBlocksN = MTILE / CTILE_ROWS;
    const int InnerBlocksM = MTILE / CTILE_COLS;
    TYPE_T localB[MTILE];
    #pragma loop_coalesce 3
    for(int ti=0;ti<OuterBlocksN;ti++)
    {
        //outer tile over columns of B
        for(int tj=0;tj<OuterBlocksM;tj++)
        {
            for(int k=0;k<K;k++)
            {
                //load it
                for(int i=0;i<MTILE/CHANNEL_UNROLL;i++)
                {
                    #pragma unroll
                    for(int j=0;j<CHANNEL_UNROLL;j++)
                    {
                        if(tj*MTILE+i*CHANNEL_UNROLL+j < M)
                            localB[i*CHANNEL_UNROLL+j]=B[(tj*MTILE+i*CHANNEL_UNROLL+j)*ldb + k];
                        else
                            localB[i*CHANNEL_UNROLL+j]=0;

                    }
                }
                //then send it
                for(int i=0;i<MTILE/CTILE_COLS;i++)
                    #pragma unroll
                    for(int j=0;j<CTILE_COLS;j++)
                        write_channel_intel(CHANNEL_MATRIX_B,localB[i*CTILE_COLS+j]);
            }
        }
    }

}
