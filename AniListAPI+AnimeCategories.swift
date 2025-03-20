import Foundation

extension AniListAPI {
    // MARK: - Anime Category Methods
    
    func fetchTrendingAnime(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: ANIME, sort: [TRENDING_DESC, POPULARITY_DESC], status_not: NOT_YET_RELEASED) {
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
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchCurrentSeasonAnime(completion: @escaping ([Anime]?) -> Void) {
        // Determine current season and year
        let (season, year) = getCurrentSeasonAndYear()
        
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($season: MediaSeason, $year: Int) {
              Page(perPage: 20) {
                media(type: ANIME, season: $season, seasonYear: $year, sort: [POPULARITY_DESC]) {
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
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": ["season": season, "year": year]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchUpcomingSeasonAnime(completion: @escaping ([Anime]?) -> Void) {
        // Determine next season and year
        let (season, year) = getNextSeasonAndYear()
        
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($season: MediaSeason, $year: Int) {
              Page(perPage: 20) {
                media(type: ANIME, season: $season, seasonYear: $year, sort: [POPULARITY_DESC]) {
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
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": ["season": season, "year": year]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchTopRankedAnime(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: ANIME, sort: [SCORE_DESC], format_in: [TV, TV_SHORT]) {
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
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchTopRankedMovies(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: ANIME, sort: [SCORE_DESC], format: MOVIE) {
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
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func fetchPopularAnime(completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query {
              Page(perPage: 20) {
                media(type: ANIME, sort: [POPULARITY_DESC], format_in: [TV, TV_SHORT]) {
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
                  episodes
                  duration
                  status
                  season
                  seasonYear
                  format
                  genres
                  averageScore
                  popularity
                  trending
                  studios {
                    nodes {
                      id
                      name
                      isAnimationStudio
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": [:]
        ]
        
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
}
