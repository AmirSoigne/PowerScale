import Foundation

extension AniListAPI {
    // MARK: - Manga Category Methods
    
    func fetchTrendingManga(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: MANGA, sort: [TRENDING_DESC, POPULARITY_DESC]) {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                  }
                  bannerImage
                  description
                  chapters
                  volumes
                  status
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchTopRankedManga(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: MANGA, sort: [SCORE_DESC]) {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                  }
                  bannerImage
                  description
                  chapters
                  volumes
                  status
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchPopularManga(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: MANGA, sort: [POPULARITY_DESC], format_in: [MANGA]) {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                  }
                  bannerImage
                  description
                  chapters
                  volumes
                  status
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchPopularManhwa(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: MANGA, sort: [POPULARITY_DESC], countryOfOrigin: "KR") {
                  id
                  title {
                    romaji
                    english
                    native
                  }
                  coverImage {
                    large
                  }
                  bannerImage
                  description
                  chapters
                  volumes
                  status
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  isAdult
                  countryOfOrigin
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
}
