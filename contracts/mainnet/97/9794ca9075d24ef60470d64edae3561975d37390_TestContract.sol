/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

contract TestContract {
    uint256 private _value;
    
    function getValue() public view returns (uint256) {
        return _value;
    }
    
    function setValue(uint256 v) public {
        _value = v;
    }
}