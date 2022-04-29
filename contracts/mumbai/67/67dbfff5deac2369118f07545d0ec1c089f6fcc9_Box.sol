pragma solidity 0.7.6;


contract Box{

    address public owner;
    uint256 public val;

    function init(address _owner)public{
        owner = _owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setVal(uint256 _val) external onlyOwner{
        val = _val;
    }

    uint256[50] private __gap;

}