// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Web3App.sol";

contract Web3AppImpl is Web3App {
    address private _proxy;
    mapping(string => string[]) private _versions;

    constructor() {}

    modifier onlyProxy() {
        require(msg.sender == _proxy, "Not called from proxy");
        _;
    }

    function setProxy(address proxy) external {
        require(_proxy == address(0), "Proxy already set");
        _proxy = proxy;
    }

    function addVersion(string memory affiliateSlug, string memory cid) external onlyProxy {
        _versions[affiliateSlug].push(cid);
    }

    function getVersionsCount(string memory affiliateSlug) external view onlyProxy returns (uint256) {
        return _versions[affiliateSlug].length;
    }

    function getList(string memory affiliateSlug, uint256 fromIndex, uint256 toIndex) external view onlyProxy returns (string[] memory) {
        require(fromIndex < toIndex, "From should be lower than to !!!");
        require(toIndex - fromIndex <= 100, "Only 100 games could be retrieved at a time !!!");
        if (toIndex > _versions[affiliateSlug].length) {
            toIndex = _versions[affiliateSlug].length;
        }

        string[] memory result = new string[](toIndex - fromIndex);
        uint256 j;
        for (uint256 i = fromIndex; i < toIndex; i++) {
            result[j++] = _versions[affiliateSlug][i];
        }
        return result;
    }

    function kill() external onlyProxy {
        selfdestruct(payable(msg.sender));
    }
}