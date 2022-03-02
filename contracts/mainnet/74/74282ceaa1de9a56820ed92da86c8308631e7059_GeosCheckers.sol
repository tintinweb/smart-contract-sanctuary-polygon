/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

library GeosCheckers {
    function sumArray(uint256[] memory _in) public pure returns(uint256 _out){
        for(uint256 i=0; i<_in.length; i++){
            _out += _in[i];
        }
    }
    function getIdFromFlat(uint256[] memory _in, uint256 _num) public pure returns(uint8){
        uint256 totalOut;
        for(uint256 i=0; i<_in.length; i++){
            totalOut += _in[i];
            if(_num <= totalOut){
                return uint8(i);
            }
        }
        return 12;
    }
    function getIdFromArr(uint256[] memory _in) public pure returns(uint8){
        return(getIdFromFlat(_in, sumArray(_in)));
    }
}