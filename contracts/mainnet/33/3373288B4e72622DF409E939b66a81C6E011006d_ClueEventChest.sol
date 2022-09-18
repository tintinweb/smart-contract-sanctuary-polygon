// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ClueEventChest {
  string public title = "#1 Escape gotchi";
  string public CLICK_ME = "https://bafybeicigzwt77wj4cvqm7sbm7ys6kvs7rut7qkdadplgl6zxftwgg2wmq.ipfs.nftstorage.link/"; // ipfs link
  string public dreams = "A horde of lickuidators entered the citaadel, this time USDT.gotchi knew that it was'nt anymore the time to think but to strike, he always was the most controversial of his kin ready to take any risk FTW. Hopefully he was'nt alone ETH.gotchi standing right behind him, never let a fren fight alone he also was the most experienced and already killed an hundreds of lickuidators, he used to be an honorable worker during the great construction at the very begining of the gotchiverse but since the back door found by the lickuidators his only goal was no more than just stake the corpses of that tongue walkers even if he is the OGiest of the gotchis he's gonna still make his proofs";  
  string public dreams2 = "NOOO ! *shouted USDC.gotchi* We are not going to release the DAI gotchis army out to support USDCT & ETH gotchi, its too dangerous ! We need them here to maintain the stability of the last ramparts of the castle, otherwise the lickuidators will REKT us (once again). USDC.gotchi I always liked your wisdom and honesty *answered UNI.gotchi* but the lickuidators... they are getting stronger day after day we have to adapt ourselves otherwise we'll just repeat the error of our ancestors that's also the reason of our existence here ! UNI.gotchi if I do this there are innocent frens that won't gonna see the sun anymore... *tock tock* Ape in please *Said USDC.gotchi*, *A hight graded entered the room* GM ser. Capitaine Anon reporting for duty, the soldiers await your orders.";
  string public shovel = "https://gotchi-web3-school.netlify.app/chest";
  uint private _end;

  constructor() {
    _end = block.timestamp + 1 days + 1 hours;
  }

  function remainingTime() external view returns(uint256) {
    return _end - block.timestamp;
  }
}