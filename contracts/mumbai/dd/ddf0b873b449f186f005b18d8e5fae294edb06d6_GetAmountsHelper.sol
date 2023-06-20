/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

interface V2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract GetAmountsHelper {
    struct outItem {
        address _routerAddress;
        uint256 amountIn;
        address[] path;
        uint256[] amounts;
        uint256 decimalsIn;
        uint256 decimalsOut;
    }

    struct InItem {
        address _routerAddress;
        uint256 amountOut;
        address[] path;
        uint256[] amounts;
        uint256 decimalsIn;
        uint256 decimalsOut;
    }

    function getAmountsOut(address _routerAddress, uint256 amountIn, address[] calldata path) private returns (uint256[] memory amounts) {
        (bool success,bytes memory returnData) = _routerAddress.call(abi.encodeWithSelector(V2Router.getAmountsOut.selector, amountIn, path));
        if (success) {
            amounts = abi.decode(returnData, (uint256[]));
        } else {
            amounts = new uint256[](0);
        }
    }

    function getAmountsIn(address _routerAddress, uint256 amountOut, address[] calldata path) private returns (uint256[] memory amounts) {
        (bool success,bytes memory returnData) = _routerAddress.call(abi.encodeWithSelector(V2Router.getAmountsIn.selector, amountOut, path));
        if (success) {
            amounts = abi.decode(returnData, (uint256[]));
        } else {
            amounts = new uint256[](0);
        }
    }

    function massGetAmountsOut(address[] calldata _routerAddressList, uint256 amountIn, address[] calldata path) external returns (outItem[] memory _list) {
        uint256 _num = _routerAddressList.length;
        _list = new outItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _list[i] = outItem({
                _routerAddress: _routerAddressList[i],
                amountIn: amountIn,
                path: path,
                amounts: getAmountsOut(_routerAddressList[i], amountIn, path),
                decimalsIn: IERC20(path[0]).decimals(),
                decimalsOut: IERC20(path[path.length - 1]).decimals()
            });
        }
    }

    function massGetAmountsIn(address[] calldata _routerAddressList, uint256 amountOut, address[] calldata path) external returns (InItem[] memory _list) {
        uint256 _num = _routerAddressList.length;
        _list = new InItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _list[i] = InItem({
                _routerAddress: _routerAddressList[i],
                amountOut: amountOut,
                path: path,
                amounts: getAmountsIn(_routerAddressList[i], amountOut, path),
                decimalsIn: IERC20(path[0]).decimals(),
                decimalsOut: IERC20(path[path.length - 1]).decimals()
            });
        }
    }
}