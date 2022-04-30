// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Drawing {
  function getRandomNumbersWithoutRepetitions(uint256 randomness)
      public pure returns (uint8[6] memory numbers)
  {
    uint8[90] memory source;
    for (uint8 i = 1; i <= 90; i++) {
      source[i - 1] = i;
    }
    for (uint i = 0; i < 6; i++) {
      uint j = i + randomness % (90 - i);
      randomness /= 90 - i;
      numbers[i] = source[j];
      source[j] = source[i];
    }
  }

  function sortNumbersByTicketCount(uint64[][90] storage ticketsByNumber, uint8[6] memory numbers)
      public view returns (uint8[6] memory)
  {
    for (uint i = 0; i < numbers.length - 1; i++) {
      uint j = i;
      for (uint k = j + 1; k < numbers.length; k++) {
        if (ticketsByNumber[numbers[k] - 1].length < ticketsByNumber[numbers[j] - 1].length) {
          j = k;
        }
      }
      if (j != i) {
        uint8 t = numbers[i];
        numbers[i] = numbers[j];
        numbers[j] = t;
      }
    }
    return numbers;
  }
}