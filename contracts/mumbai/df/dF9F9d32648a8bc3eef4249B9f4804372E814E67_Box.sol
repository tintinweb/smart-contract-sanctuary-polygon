pragma solidity 0.7.6;


contract Box{

    address private owner;
    uint256 private val;
    bool private isInitialized;
    // new
    address public admin;


    function init(address _owner, address _admin)public {
        if(isInitialized) revert("Already initialized");
        isInitialized = true;
        owner = _owner;
        admin = _admin;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setVal(uint256 _val) external onlyOwnerOrAdmin{
        val = _val + 1;
    }

    function getVal() external view returns(uint256){
        return val;
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getInitialized() external view returns(bool){
        return isInitialized;
    }

    modifier onlyOwnerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "Caller is not the owner");
        _;
    }

    uint256[49] private __gap;
}