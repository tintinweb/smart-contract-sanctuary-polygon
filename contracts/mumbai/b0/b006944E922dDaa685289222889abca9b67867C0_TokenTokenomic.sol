// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract TokenTokenomic {
    Tokenomic[] public tokenomicList;

    struct Tokenomic {
        address lockedAddress;
        address token;
        address beneficiaryAddress;
        string beneficiaryLabel;
        uint256 amount;
        uint256 amountTotal;
        uint256 amountPercentageOfMaxSupply;
        uint256 releaseTime;
        bool claimed;
    }

    function addTokenomic(Tokenomic memory tokenomic) public {
        tokenomicList.push(tokenomic);
    }    

    function setClaimed(uint256 index) public {
        tokenomicList[index].claimed = true;
    }

    function getTokenomic(address lockedAddress)
        public
        view
        returns (Tokenomic memory, uint256)
    {
        Tokenomic memory tokenomic;
        uint256 index = 0;
        for (uint256 i = 0; i < tokenomicList.length; i++) {
            if (tokenomicList[i].lockedAddress == lockedAddress) {
                tokenomic = tokenomicList[i];
                index = i;
                break;
            }
        }
        return (tokenomic, index);
    }

    function getTokenomics() public view returns (Tokenomic[] memory) {
        Tokenomic[] memory tokenomic = new Tokenomic[](tokenomicList.length);

        for (uint256 i = 0; i < tokenomicList.length; i++) {
            tokenomic[i] = tokenomicList[i];
        }

        return tokenomic;
    }
}