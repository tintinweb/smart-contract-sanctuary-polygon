// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

}

abstract contract Initializable {

    bool private _initialized;


    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


contract ProfitSplit is Initializable{
    address public constant ghstAddress=0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;

    address public a;
    address public b;
    mapping(address => address) ownerToReceiver;

    function initialize(
        address _a,
        address _b,
        address _aReceiver,
        address _bReceiver
    ) public initializer{

        a = _a;
        b = _b;
        ownerToReceiver[a] = _aReceiver;
        ownerToReceiver[b] = _bReceiver;
    }

    modifier onlyOwner{
        require(msg.sender == a || msg.sender == b);
        _;
    }

    function setOwner(address _owner) public onlyOwner{
        if(msg.sender == a){a = _owner;}
        else if(msg.sender == b){b = _owner;}
    }

    function setReceiver(address _receiver) public onlyOwner{
        if(msg.sender == a){ownerToReceiver[a] = _receiver;}
        else if(msg.sender == b){ownerToReceiver[b] = _receiver;}
    }

    function getReceiver(address user) public view returns(address){
        return ownerToReceiver[user];
    }

    function sendFunds() public onlyOwner{
        uint256 ghstBalance = IERC20(ghstAddress).balanceOf(address(this));
        uint256 aAmount = (ghstBalance * 20)  / 100;
        uint256 bAmount = (ghstBalance * 80)  / 100;
        IERC20(ghstAddress).transfer(ownerToReceiver[a], aAmount);
        IERC20(ghstAddress).transfer(ownerToReceiver[b], bAmount);

    }

    function withdrawProfits(address[] calldata _revenueTokens) public onlyOwner{

        for(uint256 i = 0; i < _revenueTokens.length; i++){

            IERC20 token = IERC20(_revenueTokens[i]);
            uint256 balance = token.balanceOf(address(this));

            uint256 aAmount = (balance * 20)  / 100;
            uint256 bAmount = (balance * 80)  / 100;

            token.transfer(ownerToReceiver[a], aAmount);
            token.transfer(ownerToReceiver[b], bAmount);
        }
    }

    /*function selfDestruct() public onlyOwner{
        address payable owner = payable(a);
        selfdestruct(owner);
    }*/

}