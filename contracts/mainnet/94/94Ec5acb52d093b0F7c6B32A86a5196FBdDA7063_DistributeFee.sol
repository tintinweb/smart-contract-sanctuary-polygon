// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract DistributeFee {
    address public owner = 0xe8884352aC947A58ecfDFd405224ed649090A531;
    address[8] public Admin = [0x3E735bf7FdCBD80c88D0De24F21B15A022A3a306, 0xF3D4Db6ca3992bE00e82A088a97810d4F7AEa80a, 0x2C55c48B4cB82Bc73C0bD1e72b78300304b4C4eC, 0x0c7EC1868aBbC5BcD73427c091517d77D1D75DE0, 0x432f25091436d0a42bB2a356F8b86e111600669F, 0xc4488680aD736A61986391F7e835fB2BFbB3881F, 0x4266595D99Bb03EB4111ca82Ee0D5394b61e535A, 0x1b587AACAce73628ebfA0bdc9ec9bA4423c4E6e4];
    IERC20 public usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256[8] feeDistribution = [20, 20, 20, 20, 5, 5, 5, 5];

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function distribute() public {
        uint256 bal = usdc.balanceOf(address(this));
        for(uint256 i=0; i<Admin.length; i++) {
            uint256 amt = (bal * feeDistribution[i])/100;
            usdc.transfer(Admin[i], amt);
        }
    }

    function changeAddress(uint256 _place, address _new) public onlyOwner {
        require(_place < 4, "Cannot change all address");
        Admin[_place] = _new;
    }
}