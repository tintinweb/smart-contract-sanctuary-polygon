/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

contract Number {
    uint256 private number;

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function getNumber() public view returns(uint256) {
        return number;
    }
}