import Foundation

extension AniListAPI {
    // MARK: - Manga Detail Methods
    
    func getMangaDetails(id: Int, completion: @escaping (Anime?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($id: Int) {
              Media(id: $id, type: MANGA) {
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
                startDate {
                  year
                  month
                  day
                }
                endDate {
                  year
                  month
                  day
                }
                genres
                tags {
                  id
                  name
                  rank
                  isAdult
                }
                staff {
                  edges {
                    role
                    node {
                      id
                      name {
                        full
                      }
                    }
                  }
                }
                averageScore
                popularity
                meanScore
                favourites
                trending
                rankings {
                  rank
                  type
                  context
                  year
                  season
                }
                relations {
                  edges {
                    id
                    relationType
                    node {
                      id
                      title {
                        romaji
                        english
                      }
                      type
                      format
                      coverImage {
                        large
                      }
                    }
                  }
                }
                characters(sort: ROLE, perPage: 10) {
                  edges {
                    node {
                      id
                      name {
                        full
                      }
                      image {
                        medium
                      }
                    }
                    role
                  }
                }
                externalLinks {
                  id
                  url
                  site
                  type
                }
                recommendations(sort: RATING_DESC, perPage: 5) {
                  nodes {
                    mediaRecommendation {
                      id
                      title {
                        romaji
                        english
                      }
                      coverImage {
                        large
                      }
                    }
                  }
                }
                isAdult
              }
            }
            """,
            "variables": ["id": id]
        ]
        
        fetchSingleData(graphqlQuery: graphqlQuery, completion: completion)
    }
    
    func searchManga(query: String, completion: @escaping ([Anime]?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($search: String) {
              Page(perPage: 10) {
                media(search: $search, type: MANGA) {
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
                  startDate {
                    year
                    month
                    day
                  }
                  endDate {
                    year
                    month
                    day
                  }
                  genres
                  tags {
                    id
                    name
                    category
                    isAdult
                  }
                  staff {
                    edges {
                      role
                      node {
                        id
                        name {
                          full
                        }
                      }
                    }
                  }
                  averageScore
                  popularity
                  meanScore
                  favourites
                  rankings {
                    rank
                    type
                    context
                    year
                    season
                  }
                  relations {
                    edges {
                      id
                      relationType
                      node {
                        id
                        title {
                          romaji
                          english
                        }
                        type
                        format
                        coverImage {
                          large
                        }
                      }
                    }
                  }
                  characters(sort: ROLE, perPage: 6) {
                    edges {
                      node {
                        id
                        name {
                          full
                        }
                        image {
                          medium
                        }
                      }
                      role
                    }
                  }
                  externalLinks {
                    id
                    url
                    site
                    type
                  }
                  recommendations(sort: RATING_DESC, perPage: 5) {
                    nodes {
                      mediaRecommendation {
                        id
                        title {
                          romaji
                          english
                        }
                        coverImage {
                          large
                        }
                      }
                    }
                  }
                  isAdult
                }
              }
            }
            """,
            "variables": ["search": query]
        ]
        fetchData(graphqlQuery: graphqlQuery, completion: completion)
    }
}
