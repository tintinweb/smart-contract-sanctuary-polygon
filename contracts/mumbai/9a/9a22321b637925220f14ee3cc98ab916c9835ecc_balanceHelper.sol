/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}

contract balanceHelper {

    struct tokenInfo {
          string name;
          string symbol;
          uint256 decimals;
    }

    struct userinfoS {
        address _user;
        uint256 _gas;
        uint256 _tokenBalance;
    }

    function getBalance0(address[] memory _addressList) external view returns (userinfoS[] memory userinfoList) {
            uint256 num = _addressList.length;
            userinfoList  = new userinfoS[](num);
            for (uint256 i=0;i<num;i++){
                userinfoList[i] = userinfoS(_addressList[i], _addressList[i].balance, 0);
            }
    }
    
    function getBalance1(address[] memory _addressList, address _token) external view returns (userinfoS[] memory userinfoList,tokenInfo memory tokenDetail) {
            uint256 num = _addressList.length;
            userinfoList  = new userinfoS[](num);
            for (uint256 i=0;i<num;i++){
                if (_token != address(0)) {
                userinfoList[i] = userinfoS(_addressList[i], _addressList[i].balance, IERC20(_token).balanceOf(_addressList[i]));
                } else {
                    userinfoList[i] = userinfoS(_addressList[i], _addressList[i].balance, 0);
                }
            }
            if (_token != address(0)) {
                 tokenDetail = tokenInfo(IERC20(_token).name(), IERC20(_token).symbol(), IERC20(_token).decimals());
            }
    }
}