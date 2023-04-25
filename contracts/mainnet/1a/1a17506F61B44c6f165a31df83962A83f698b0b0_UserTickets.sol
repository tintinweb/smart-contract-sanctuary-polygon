// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @notice This library manages an index data structure that allows retrieving the tickets that
///   played a given combination of numbers efficiently in O(1).
/// @notice The data structure is stored as a `mapping(uint256 => uint)` whose keys are "hashes" of
///   ticket numbers and the values are the number of times those numbers have been played in a
///   ticket. The hashes are calculated by multiplying the prime numbers corresponding to the played
///   numbers: for instance, the map key corresponding to three numbers `n0`, `n1`, and `n2`, is
///   `getPrime(n0) * getPrime(n1) * getPrime(n2)`. The use of prime numbers allows indexing all
///   combinations of a ticket independently of the order of the numbers.
library TicketIndex {
  bytes32 constant _WORD1 = 0x01020305070b0d1113171d1f25292b2f353b3d4347494f53596165676b6d717f;
  bytes32 constant _WORD2 = 0x83898b95979da3a7adb3b5bfc1c5c7d3dfe3e5e9eff1fb000000000000000000;
  bytes32 constant _WORD3 = 0x01010107010d010f01150119011b0125013301370139013d014b0151015b015d;
  bytes32 constant _WORD4 = 0x01610167016f0175017b017f0185018d0191019901a301a501af01b101b701bb;
  bytes32 constant _WORD5 = 0x01c101c901cd01cf000000000000000000000000000000000000000000000000;

  error UnknownPrimeError(uint8 i);

  /// @dev Returns the i-th prime. `i` must be less than or equal to 90.
  function getPrime(uint8 i) internal pure returns (uint16) {
    if (i <= 31) return uint8(bytes1(_WORD1 << (i * 8)));
    if (i <= 54) return uint8(bytes1(_WORD2 << ((i - 32) * 8)));
    if (i <= 70) return uint16(bytes2(_WORD3 << ((i - 55) * 16)));
    if (i <= 86) return uint16(bytes2(_WORD4 << ((i - 71) * 16)));
    if (i <= 90) return uint16(bytes2(_WORD5 << ((i - 87) * 16)));
    revert UnknownPrimeError(i);
  }

  /// @dev Returns the binomial coefficient (n choose 2).
  function _choose2(uint n) private pure returns (uint) {
    if (n <= 1) {
      return 0;
    }
    return n * (n - 1) / 2;
  }

  /// @dev Returns the binomial coefficient (n choose 3).
  function _choose3(uint n) private pure returns (uint) {
    if (n <= 2) {
      return 0;
    }
    return n * (n - 1) * (n - 2) / 6;
  }

  /// @dev Returns the binomial coefficient (n choose 4).
  function _choose4(uint n) private pure returns (uint) {
    if (n <= 3) {
      return 0;
    }
    return n * (n - 1) * (n - 2) * (n - 3) / 24;
  }

  /// @notice Indexes a ticket in the `index`.
  /// @param index The data structure where the ticket is indexed.
  /// @param numbers The numbers in the ticket (must be at least 6).
  function indexTicket(
      mapping(uint256 => uint) storage index,
      uint8[] calldata numbers) public returns (uint256 hash)
  {
    uint combinations2 = _choose4(numbers.length - 2);
    uint combinations3 = _choose3(numbers.length - 3);
    uint combinations4 = _choose2(numbers.length - 4);
    uint combinations5 = numbers.length - 5;
    uint256[] memory p = new uint256[](numbers.length);
    hash = 1;
    for (uint i = 0; i < numbers.length; i++) {
      uint256 prime = getPrime(numbers[i]);
      p[i] = prime;
      hash *= prime;
    }
    for (uint i0 = 0; i0 < p.length; i0++) {
      for (uint i1 = i0 + 1; i1 < p.length; i1++) {
        index[p[i0] * p[i1]] += combinations2;
        for (uint i2 = i1 + 1; i2 < p.length; i2++) {
          index[p[i0] * p[i1] * p[i2]] += combinations3;
          for (uint i3 = i2 + 1; i3 < p.length; i3++) {
            index[p[i0] * p[i1] * p[i2] * p[i3]] += combinations4;
            for (uint i4 = i3 + 1; i4 < p.length; i4++) {
              index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4]] += combinations5;
              for (uint i5 = i4 + 1; i5 < p.length; i5++) {
                index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4] * p[i5]]++;
              }
            }
          }
        }
      }
    }
  }

  /// @notice Indexes a 6-number ticket in the `index`. This is exactly the same as calling
  ///   `indexTicket` with 6 numbers, only it's a bit more gas-efficient because it's optimized for
  ///   tickets with 6 numbers.
  /// @param index The data structure where the ticket is indexed.
  /// @param numbers The 6 numbers in the ticket.
  function indexTicket6(
      mapping(uint256 => uint) storage index,
      uint8[6] calldata numbers) public returns (uint256 hash)
  {
    uint256 p0 = getPrime(numbers[0]);
    uint256 p1 = getPrime(numbers[1]);
    uint256 p2 = getPrime(numbers[2]);
    uint256 p3 = getPrime(numbers[3]);
    uint256 p4 = getPrime(numbers[4]);
    uint256 p5 = getPrime(numbers[5]);
    hash = p0 * p1 * p2 * p3 * p4 * p5;
    index[p0 * p1]++;
    index[p0 * p2]++;
    index[p0 * p3]++;
    index[p0 * p4]++;
    index[p0 * p5]++;
    index[p1 * p2]++;
    index[p1 * p3]++;
    index[p1 * p4]++;
    index[p1 * p5]++;
    index[p2 * p3]++;
    index[p2 * p4]++;
    index[p2 * p5]++;
    index[p3 * p4]++;
    index[p3 * p5]++;
    index[p4 * p5]++;
    index[p0 * p1 * p2]++;
    index[p0 * p1 * p3]++;
    index[p0 * p1 * p4]++;
    index[p0 * p1 * p5]++;
    index[p0 * p2 * p3]++;
    index[p0 * p2 * p4]++;
    index[p0 * p2 * p5]++;
    index[p0 * p3 * p4]++;
    index[p0 * p3 * p5]++;
    index[p0 * p4 * p5]++;
    index[p1 * p2 * p3]++;
    index[p1 * p2 * p4]++;
    index[p1 * p2 * p5]++;
    index[p1 * p3 * p4]++;
    index[p1 * p3 * p5]++;
    index[p1 * p4 * p5]++;
    index[p2 * p3 * p4]++;
    index[p2 * p3 * p5]++;
    index[p2 * p4 * p5]++;
    index[p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3]++;
    index[p0 * p1 * p2 * p4]++;
    index[p0 * p1 * p2 * p5]++;
    index[p0 * p1 * p3 * p4]++;
    index[p0 * p1 * p3 * p5]++;
    index[p0 * p1 * p4 * p5]++;
    index[p0 * p2 * p3 * p4]++;
    index[p0 * p2 * p3 * p5]++;
    index[p0 * p2 * p4 * p5]++;
    index[p0 * p3 * p4 * p5]++;
    index[p1 * p2 * p3 * p4]++;
    index[p1 * p2 * p3 * p5]++;
    index[p1 * p2 * p4 * p5]++;
    index[p1 * p3 * p4 * p5]++;
    index[p2 * p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3 * p4]++;
    index[p0 * p1 * p2 * p3 * p5]++;
    index[p0 * p1 * p2 * p4 * p5]++;
    index[p0 * p1 * p3 * p4 * p5]++;
    index[p0 * p2 * p3 * p4 * p5]++;
    index[p1 * p2 * p3 * p4 * p5]++;
    index[p0 * p1 * p2 * p3 * p4 * p5]++;
  }

  /// @notice Calculates the number of winning 6-combinations in each winning category given the 6
  ///   drawn numbers. `winners[0]` is the number of combinations with 2 matches, `winners[1]` is
  ///   the number of combinations with 3 matches, etc. Some of the returned numbers may be 0. This
  ///   is a fundamental piece of the lottery because when a user withdraws the prize of a ticket it
  ///   must be calculated as the prize allocated for the category divided by the number of winners
  ///   in the category.
  /// @param index The index data structure where all tickets for the round have been indexed (see
  ///   the `indexTicket` and `indexTicket6` methods).
  /// @param numbers The 6 drawn numbers.
  function findWinners(
      mapping(uint256 => uint) storage index,
      uint8[6] memory numbers) public view returns (uint[5] memory winners)
  {
    winners = [
      uint(0),  // tickets matching exactly 2 numbers
      0,        // tickets matching exactly 3 numbers
      0,        // tickets matching exactly 4 numbers
      0,        // tickets matching exactly 5 numbers
      0         // tickets matching exactly 6 numbers
    ];
    uint256[6] memory p = [
      uint256(getPrime(numbers[0])),
      uint256(getPrime(numbers[1])),
      uint256(getPrime(numbers[2])),
      uint256(getPrime(numbers[3])),
      uint256(getPrime(numbers[4])),
      uint256(getPrime(numbers[5]))
    ];
    for (uint i0 = 0; i0 < 6; i0++) {
      for (uint i1 = i0 + 1; i1 < 6; i1++) {
        winners[0] += index[p[i0] * p[i1]];
        for (uint i2 = i1 + 1; i2 < 6; i2++) {
          winners[1] += index[p[i0] * p[i1] * p[i2]];
          for (uint i3 = i2 + 1; i3 < 6; i3++) {
            winners[2] += index[p[i0] * p[i1] * p[i2] * p[i3]];
            for (uint i4 = i3 + 1; i4 < 6; i4++) {
              winners[3] += index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4]];
              for (uint i5 = i4 + 1; i5 < 6; i5++) {
                winners[4] += index[p[i0] * p[i1] * p[i2] * p[i3] * p[i4] * p[i5]];
              }
            }
          }
        }
      }
    }
    delete p;
    winners[3] -= winners[4] * 6;
    winners[2] -= winners[3] * 5 + winners[4] * 15;
    winners[1] -= winners[2] * 4 + winners[3] * 10 + winners[4] * 20;
    winners[0] -= winners[1] * 3 + winners[2] * 6 + winners[3] * 10 + winners[4] * 15;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TicketIndex.sol';


struct TicketData {
  /// @dev This is not properly a "hash": it's calculated by multiplying the prime numbers
  ///   corresponding to the numbers of the ticket. See the note on `TicketIndex` for more details.
  ///   The resulting value allows retrieving all the numbers in the ticket and it's more efficient
  ///   than storing them separately.
  uint256 hash;

  /// @dev The timestamp of the transaction that bought the ticket.
  uint128 timestamp;

  /// @dev The unique ID of the ticket.
  uint64 id;

  /// @dev The round number of the ticket.
  uint32 round;

  /// @dev The number of numbers in the ticket, e.g. 6 for a 6-number ticket. Note that `hash` is
  ///   the product of `cardinality` different primes.
  uint16 cardinality;

  /// @dev Whether or not the prize attributed to the ticket has been withdrawn by the user.
  bool withdrawn;
}


error InvalidTicketIdError(uint ticketId);


library UserTickets {
  function _lowerBound(TicketData[] storage tickets, uint round) private view returns (uint) {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (round > tickets[k].round) {
        i = k + 1;
      } else {
        j = k;
      }
    }
    return i;
  }

  function _upperBound(TicketData[] storage tickets, uint round) private view returns (uint) {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (round < tickets[k].round) {
        j = k;
      } else {
        i = k + 1;
      }
    }
    return j;
  }

  function getTicketIds(TicketData[] storage tickets) public view returns (uint[] memory ids) {
    ids = new uint[](tickets.length);
    for (uint i = 0; i < tickets.length; i++) {
      ids[i] = tickets[i].id;
    }
  }

  function getTicketIdsForRound(TicketData[] storage tickets, uint round)
      public view returns (uint[] memory ids)
  {
    uint min = _lowerBound(tickets, round);
    uint max = _upperBound(tickets, round);
    if (max < min) {
      max = min;
    }
    ids = new uint[](max - min);
    for (uint i = min; i < max; i++) {
      ids[i - min] = tickets[i].id;
    }
  }

  function getTicket(TicketData[] storage tickets, uint ticketId)
      public view returns (TicketData storage)
  {
    uint i = 0;
    uint j = tickets.length;
    while (j > i) {
      uint k = i + ((j - i) >> 1);
      if (ticketId < tickets[k].id) {
        j = k;
      } else if (ticketId > tickets[k].id) {
        i = k + 1;
      } else {
        return tickets[k];
      }
    }
    revert InvalidTicketIdError(ticketId);
  }

  function _getTicketNumbers(TicketData storage ticket)
      private view returns (uint8[] memory numbers)
  {
    numbers = new uint8[](ticket.cardinality);
    uint i = 0;
    for (uint8 j = 1; j <= 90; j++) {
      if (ticket.hash % TicketIndex.getPrime(j) == 0) {
        numbers[i++] = j;
      }
    }
  }

  function getTicketAndNumbers(
      TicketData[] storage tickets, uint ticketId)
      public view returns (TicketData storage, uint8[] memory numbers)
  {
    TicketData storage ticket = getTicket(tickets, ticketId);
    return (ticket, _getTicketNumbers(ticket));
  }
}