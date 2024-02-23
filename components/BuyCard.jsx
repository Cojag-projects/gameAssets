import React, { useContext, useState, useEffect } from "react";
import Link from "next/link";
import { NFTContext } from "../context/NFTContext";
import {
  useConnectionStatus,
  useDisconnect,
  useAddress,
} from "@thirdweb-dev/react"; 

const BuyCard = ({ nft, onProfilePage }) => {
  const { nftCurrency } = useContext(NFTContext);
  const ownerAddress = nft.owner.toLowerCase();
  const currentAccountAddress = useAddress() ? useAddress().toLowerCase() : null;

  return (
    <div
      className="flex flex-col rounded-3xl border-solid hover:border-dotted m-3"
      style={{ backgroundColor: "#011627 " }}
    >
      <div className="px-4 py-7 sm:p-10 sm:pb-6">
        <div className="grid items-center justify-center w-full grid-cols-1 text-left">
          <div>
            <h2 className="text-lg font-medium tracking-tighter text-white lg:text-3xl">
              {nft.name}
            </h2>
            <p className="mt-6 text-sm text-gray-100">ID: {nft.id}</p>
          </div>
          {ownerAddress === currentAccountAddress  ? (
            <></>
          ) : nft.sold ? (
            <>This NFT is already sold.</>
          ) : (
            <>
              {nft.forSale ? (
                <div className="mt-6">
                  <p>
                    <span className="text-5xl font-light tracking-tight text-white">
                      {nft.price}
                    </span>
                    <span className="text-base font-medium text-white">
                      {" "}
                      {nftCurrency(nft)}{" "}
                    </span>
                  </p>
                </div>
              ) : (
                <div className="mt-6">
                  <p className="text-base font-medium text-white">
                    Not for sale
                  </p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
      <Link href={{ pathname: "/nft-details", query: nft }}>
        <div className="flex px-6 pb-8 sm:px-8">
          <a
            aria-describedby="tier-starter"
            className="items-center justify-center w-full px-6 py-2.5 text-center text-black duration-200 bg-white border-2 border-white rounded-full inline-flex hover:bg-transparent hover:border-white hover:text-white focus:outline-none focus-visible:outline-white text-sm focus-visible:ring-white"
            href="#"
          >
            View More
          </a>
        </div>
      </Link>
    </div>
  );
};

export default BuyCard;