// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CardsHoldingInterface.sol";

contract CardsHolding is CardsHoldingInterface {
    uint256[] internal cards;
    uint256[] internal firstFlipNumbers;
    uint256[] private firstFlipCards = [
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        8,
        6,
        4,
        5,
        9,
        10,
        4,
        5,
        9,
        10,
        4,
        5,
        9,
        10,
        2,
        3,
        11,
        12,
        2,
        3,
        11,
        12,
        1,
        13,
        1,
        13
    ];
    address _owner;

    // uint32 private MAX_WORDS;
    // uint32 private BUFFER_WORDS;

    // function getNextCard()
    //     external
    //     returns (uint256 card, bool shouldTriggerDraw)
    // {
    //     if (_currentCard.current() > BUFFER_WORDS) {
    //         shouldTriggerDraw = true;
    //     }
    //     if (_currentCard.current() >= MAX_WORDS) {
    //         _currentCard.reset();
    //     }
    //     uint256 currentCard = _currentCard.current();
    //     _currentCard.increment();
    //     card = cards[currentCard];
    // }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner can call this function");
        _;
    }

    //need to understand buffer concept
    function getNextCard() external override returns (uint256) {
        require(cards.length > 0, "Not enough cards to draw");
        uint256 card = cards[cards.length - 1];
        cards.pop();
        return card;
    }

    // function storeCards(uint256[] memory cardValues) external {
    //     for (uint256 index = 0; index < MAX_WORDS; index++) {
    //         cards[index] = (cardValues[index] % 13) + 1;
    //     }
    //     _currentCard.reset();
    // }

    function storeCards(uint256[] memory cardValues)
        external
        override
        onlyOwner
    {
        require(cardValues.length > 0, "Plese ensure correct input");

        for (uint256 index = 0; index < cardValues.length; index++) {
            cards.push((cardValues[index] % 13) + 1);
            firstFlipNumbers.push((cardValues[index] % 96) + 1);
        }
    }

    function getFirstFlipCard() external override returns (uint256) {
        require(firstFlipNumbers.length > 0, "Not enough cards to draw");
        uint256 card = firstFlipCards[firstFlipNumbers.length - 1];
        firstFlipNumbers.pop();
        return card;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface CardsHoldingInterface {
    function getNextCard() external returns (uint256 card);

    function storeCards(uint256[] memory cardValues) external;

    function getFirstFlipCard() external returns (uint256);
}