// contracts/ERC721/aggregator_contract/MagicAggregator.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface MintInterface{
    function mint(address _userWallet, uint256 _quantity) external payable;
}

contract MagicAggregator {
    // event StringFailure(string stringFailure);
    // event BytesFailure(bytes bytesFailure);
    // event SuccessMessage(string successMessage);
    event Response(bool success, bytes data, address contract_address, string function_name, uint256 amount);

    constructor() {}

    // function _getError(bytes memory _errData) private pure returns (string memory) {
    //     return abi.decode(_errData[4:], (string));
    // }

    function batchMint721(
        address wallet,
        address payable[] calldata contracts,
        string[] memory function_names,
        uint256[] calldata amounts
    ) external payable {
        // All arrays must be equal
        require(
            contracts.length == amounts.length &&
            contracts.length == function_names.length,
            "all arrays must be equal length"
        );
        string memory abi_params = "(address,uint256)";

        // Loop through the contracts and mint
        for (uint i=0; i<contracts.length; i++) {
            // require(to_wallets[i] != address(0), "ERC1155: mint to the zero address");
            // MintInterface underlying_contract = MintInterface(contracts[i]);
            // try underlying_contract.mint(to_wallets[i], amounts[i]) {
            string memory abi_str = string.concat(function_names[i], abi_params);
            // string memory abi_str = "mint(address,uint256)";
            (bool success, bytes memory data) = contracts[i].call(abi.encodeWithSignature(abi_str, wallet, amounts[i]));
            
            emit Response(success, data, contracts[i], function_names[i], amounts[i]);
            // try  {
            //     emit SuccessMessage("Minted");
            // } catch Error(string memory _err) {
            //     emit StringFailure(_err);
            // } catch (bytes memory _err) {
            //     emit BytesFailure(_err);
            // }
        }
    }
}