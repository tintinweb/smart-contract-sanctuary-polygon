/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract RaffleWinnerPicker {
    uint256 public _numWinners = 2;
    address[] public _inputWallets = [0xacB9684f762108dae82Ff7FE202b08F135749C08,0x18cCC241CcE98a67564E367eBc1F1f0e692E3188,0xA3dec8Ce4d2cf00EDc13bB018f55fC8be5C09569,0x500898B272D3454D7Ce39c1E99b469deffD92B74,0x85001c23C185f473Cf0FFA5C5c9532626B36c1Eb,0xc8030B11Ff7052436D9670188d00890B9F48A06A,0xe9d4f4f93C7C0EBF3BdfED9EFf721476Ce951E61,0xd532962FD7976880FDff92DB9Cbe48a7369b1fc0,0x8101c452Ed4Ae5C0aF5385eb5dfcA47Ee0EFfd32,0xbaab0E1707AB6DdA962d18ab39499ca464B3f58a];

    address[] public _selectedWallets;

    constructor() {
        require(_numWinners > 0, "numWinners must be greater than 0");
        require(
            _inputWallets.length > 0,
            "inputWallets.length must be greater than 0"
        );
        uint256 count = 0;
        uint256 nonce = 0;
        while (count < _numWinners) {
            uint256 randIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            ) % _inputWallets.length;
            _selectedWallets.push(_inputWallets[randIndex]);
            nonce++;
            count++;
        }
    }

    function inputWallets() public view returns (address[] memory) {
        return _inputWallets;
    }

    function selectedWallets() public view returns (address[] memory) {
        return _selectedWallets;
    }
}