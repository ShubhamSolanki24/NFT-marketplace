// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract NFTMarketplace {
  using Counters for Counters.Counter;
  Counters.Counter private _itemCounter;
  Counters.Counter private _itemSoldCounter;
  address payable public marketowner;
  uint256 public listingFee = 0.0005 ether;

  enum State { Created, Release, Idle }

  struct MarketItem {
    uint id;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable buyer;
    uint256 price;
    State state;
  }
  mapping(uint256 => MarketItem) private marketItems;
  event MarketItemCreated (
    uint indexed id,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256 price,
    State state
  );

  event MarketItemSold (
    uint indexed id,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address buyer,
    uint256 price,
    State state
  );
  constructor() {
    marketowner = payable(msg.sender);
  }
    //It returns the setup fee on the marketplace
  function getListingFee() public view returns (uint256) {
    return listingFee;
  }
  
//  create a MarketItem for NFT sale on the marketplace.
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable {
    require(price > 0, "Minimum price must be at least 1 wei");
    require(msg.value == listingFee, "Fee must be equal to listing fee");
    _itemCounter.increment();
    uint256 id = _itemCounter.current();
    marketItems[id] =  MarketItem(
      id,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      State.Created
    );

    require(IERC721(nftContract).getApproved(tokenId) == address(this), "NFT must be approved to market");
    // change to approve mechanism from the original direct transfer to market
    // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    emit MarketItemCreated(
      id,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      State.Created
    );
  }
    // delete a MarketItem from the marketplace.
  function deleteMarketItem(uint256 itemId) public {
    require(itemId <= _itemCounter.current(), "id must be less then the item counter");
    require(marketItems[itemId].state == State.Created, "item must be on NFTmarketplace");
    MarketItem storage item = marketItems[itemId];
    require(IERC721(item.nftContract).ownerOf(item.tokenId) == msg.sender, "must be the owner");
    require(IERC721(item.nftContract).getApproved(item.tokenId) == address(this), "NFT must be approved to market");
    item.state = State.Idle;
     emit MarketItemSold(
      itemId,
      item.nftContract,
      item.tokenId,
      item.seller,
      address(0),
      0,
      State.Idle
    );
  }
  /* Transfers ownership of the item, as well as funds
   * NFT will go from seller to buyer
   * money will go from buyer to seller
   * listingFee will go from contract to marketowner
   */
  function createMarketSale(
    address nftContract,
    uint256 id
  ) public payable {
    MarketItem storage item = marketItems[id];
    uint price = item.price;
    uint tokenId = item.tokenId;
    require(msg.value == price, "Please submit the asking price");
    require(IERC721(nftContract).getApproved(tokenId) == address(this), "NFT must be approved to market");
    item.buyer = payable(msg.sender);
    item.state = State.Release;
    _itemSoldCounter.increment();    
    IERC721(nftContract).transferFrom(item.seller, msg.sender, tokenId);
    payable(marketowner).transfer(listingFee);
    item.seller.transfer(msg.value);
    emit MarketItemSold(
      id,
      nftContract,
      tokenId,
      item.seller,
      msg.sender,
      price,
      State.Release
    );    
  }
    enum FetchOperator { ActiveItems, MyPurchasedItems, MyCreatedItems}
  /*  Returns all unsold market items condition: 
   *  1) state == Created
   *  2) buyer = 0x0
   *  3) still have approve
   */

  function fetchActiveItems() public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.ActiveItems);
  }
  // Returns only market items a user has purchased
  function fetchMyPurchasedItems() public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.MyPurchasedItems);
  }
  //Returns only market items a user has created
  function fetchMyCreatedItems() public view returns (MarketItem[] memory) {
    return fetchHepler(FetchOperator.MyCreatedItems);
  }
 
// helper to build condition
   // todo should reduce duplicate contract call here
  // (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
   
  function isCondition(MarketItem memory item, FetchOperator _operator) private view returns (bool){
    if(_operator == FetchOperator.MyCreatedItems){ 
      return 
        (item.seller == msg.sender
          && item.state != State.Idle
        )? true
         : false;
    }else if(_op == FetchOperator.MyPurchasedItems){
      return
        (item.buyer ==  msg.sender) ? true: false;
    }else if(_op == FetchOperator.ActiveItems){
      return 
        (item.buyer == address(0) 
          && item.state == State.Created
          && (IERC721(item.nftContract).getApproved(item.tokenId) == address(this))
        )? true
         : false;
    }else{
      return false; 
    }}
}
//helperfetcher function
   function fetchHepler(FetchOperator _operator) private view returns (MarketItem[] memory) {     
    uint total = _itemCounter.current();
    uint itemCount = 0;
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _operator)) {
        itemCount ++;
      }
    }
    uint index = 0;
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 1; i <= total; i++) {
      if (isCondition(marketItems[i], _operator)) {
        items[index] = marketItems[i];
        index ++;
      }
    }
    return items;
  } 

  