#!/usr/bin/env python3
import sys, json
from ytmusicapi import YTMusic

def main():
    query = " ".join(sys.argv[1:])
    if not query:
        print(json.dumps([]))
        return

    ytmusic = YTMusic()
    results = ytmusic.search(query, limit=10, filter="songs")

    output = []
    for song in results:
        output.append({
            "title": song.get("title"),
            "artist": song.get("artists")[0]["name"] if song.get("artists") else "",
            "video_id": song.get("videoId"),
            "duration": song.get("duration")
        })

    print(json.dumps(output))

if __name__ == "__main__":
    main()

