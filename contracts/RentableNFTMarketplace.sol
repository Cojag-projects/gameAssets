// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC4907.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "usingtellor/contracts/UsingTellor.sol";



contract RentableNFTMarketplace is ERC4907, UsingTellor{

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _itemsSold;
    mapping(uint256 => string) public tokenURIs;


    uint256 listingPrice = 1 ether;
    address payable public owner;
    address payable _tellorAddress = payable(0x840c23e39F9D029fFa888F47069aA6864f0401D7);

    mapping(uint256 => MarketItem) public idToMarketItem;

    struct MarketItem {
      uint256 tokenId;
      address payable seller;
      address payable owner;
      uint256 price;
      uint256 rentPrice;
      bool originalForRent;
      bool originalForSale;
      uint64 expires;
      bool forRent;
      bool forSale;
      bool sold;
      bool rented;
    }

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      uint256 rentPrice,
      bool originalForRent,
      bool originalForSale,
      uint64 expires,
      bool forRent,
      bool forSale,
      bool sold,
      bool rented
    );

    modifier onlyOwner(uint256 _tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "caller is not owner nor approved"
        );
        _;
    }

    constructor() ERC4907("Rentable", "RT") UsingTellor(_tellorAddress){
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint _listingPrice) public payable {
      require(owner == msg.sender, "owner");
      listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
      return listingPrice;
    }

    function createToken(string memory _tokenURI, uint256 price, uint256 rent_price, bool forSale, bool forRent, bool member) public payable {
      require(member || msg.value == listingPrice, "Price must be equal to listing price");
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();
      _mint(msg.sender, newTokenId);
      tokenURIs[newTokenId] = _tokenURI;
      createMarketItem(newTokenId, price, rent_price , forSale, forRent);
    }

    function createMarketItem(
      uint256 tokenId,
      uint256 price,
      uint256 rent_price,
      bool forSale,
      bool forRent
    ) private {
      require(!forSale || price > 0, "price required");
      require(!forRent || rent_price > 0, "rent price required");
  
      idToMarketItem[tokenId] =  MarketItem(
        tokenId,
        payable(msg.sender),
        payable(address(this)),
        price,
        rent_price,
        forRent,
        forSale,
        0,
        forRent,
        forSale,
        false,
        false
      );
      _transfer(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        rent_price,
        forRent,
        forSale,
        0,
        forRent,
        forSale,
        false,
        false
      );
    }

    function resellToken(uint256 tokenId, uint256 price, uint256 rent_price, bool forRent, bool forSale, bool member) public payable {
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      require(member || msg.value == listingPrice, "Price must be equal to listing price");
      idToMarketItem[tokenId].sold = false;
      idToMarketItem[tokenId].price = price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));
      idToMarketItem[tokenId].rentPrice = rent_price;
      idToMarketItem[tokenId].originalForRent = forRent;
      idToMarketItem[tokenId].originalForSale = forSale;
      idToMarketItem[tokenId].forRent = forRent;
      idToMarketItem[tokenId].forSale = forSale;
      idToMarketItem[tokenId].expires = 0;
      idToMarketItem[tokenId].rented = false;
      _itemsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }

    function createMarketSale(
      uint256 tokenId
      ) public payable {
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      require(msg.value>= price, "Please pay the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _itemsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      payable(seller).transfer(msg.value);
    }

function rentOutToken(
    uint256 _tokenId,
    uint64 _expires
) public payable {
    MarketItem storage marketItem = idToMarketItem[_tokenId];
    
    require(marketItem.forRent, "Token is not available for rent");
    require(userOf(_tokenId) == address(0), "Token is already rented");
    require(msg.value >= marketItem.rentPrice, "Insufficient funds to rent the token");

    idToMarketItem[_tokenId].rented = true;
    idToMarketItem[_tokenId].originalForRent = idToMarketItem[_tokenId].forRent;
    idToMarketItem[_tokenId].originalForSale = idToMarketItem[_tokenId].forSale;
    idToMarketItem[_tokenId].expires = _expires;
    
    idToMarketItem[_tokenId].forRent = false;
    idToMarketItem[_tokenId].forSale = false;
    _setUser(_tokenId, msg.sender, _expires);
}

function checkExpiryAndResetState(uint256 _tokenId) public {
    MarketItem storage marketItem = idToMarketItem[_tokenId];

    // Check if the rental period has expired
    if (block.timestamp > marketItem.expires) {
        // Reset the forRent and forSale to their original values
        idToMarketItem[_tokenId].forRent = idToMarketItem[_tokenId].originalForRent;
        idToMarketItem[_tokenId].forSale = idToMarketItem[_tokenId].originalForSale;
        idToMarketItem[_tokenId].rented = false;  
        // Optionally, you might want to reset the user of the token
        _setUser(_tokenId, address(0), 0);
    }
}
    // Add a new function to return all available items for buy and rent
function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // Add a new function to return all items owned by the user
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // Add a new function to return all items rented by the user
    // function fetchMyRentedNFTs() public view returns (MarketItem[] memory) {
    //     uint totalItemCount = _tokenIds.current();
    //     uint itemCount = _itemsSold.current();
    //     uint currentIndex = 0;

    //     MarketItem[] memory items = new MarketItem[](itemCount);
    //     for (uint i = 0; i < totalItemCount; i++) {
    //         if (userOf(i + 1) == msg.sender) {
    //             uint currentId = i + 1;
    //             MarketItem storage currentItem = idToMarketItem[currentId];
    //             items[currentIndex] = currentItem;
    //             currentIndex += 1;
    //         }
    //     }

    //     return items;
    // }
  function fetchMyRentedNFTs() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint[] memory rentedItemIds = new uint[](totalItemCount);

      // Loop through all NFTs to find rented items owned by the user
      for (uint i = 0; i < totalItemCount; i++) {
          if (userOf(i + 1) == msg.sender) {
              rentedItemIds[itemCount] = i + 1;
              itemCount += 1;
          }
      }

      // Create an array to store rented items
      MarketItem[] memory items = new MarketItem[](itemCount);

      // Populate the items array with rented items
      for (uint i = 0; i < itemCount; i++) {
          uint currentId = rentedItemIds[i];
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[i] = currentItem;
      }

      return items;
  }

    function updateRentPrice(uint256 _tokenId,uint256 rent_price) public{
        require(idToMarketItem[_tokenId].seller == msg.sender, "Only item owner can perform this operation");
        idToMarketItem[_tokenId].rentPrice = rent_price;
    }

    function updatePrice(uint256 _tokenId,uint256 price) public{
        require(idToMarketItem[_tokenId].seller == msg.sender, "Only item owner can perform this operation");
        idToMarketItem[_tokenId].price = price;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        // return string(abi.encodePacked("ipfs://",tokenURIs[_tokenId],"/metadata.json"));
        return string(abi.encodePacked(tokenURIs[_tokenId]));

    }

    function withdraw() public {
      require(msg.sender == owner, "Only owner can withdraw");
      uint balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}