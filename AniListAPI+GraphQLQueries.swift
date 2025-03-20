import Foundation

extension AniListAPI {
    // MARK: - GraphQL Query Constants
    
    struct Queries {
        // MARK: - Anime Queries
        
        static let animeSearch = """
        query ($search: String) {
          Page(perPage: 10) {
            media(search: $search, type: ANIME) {
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
              studios {
                nodes {
                  id
                  name
                  isAnimationStudio
                }
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
              nextAiringEpisode {
                airingAt
                timeUntilAiring
                episode
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
                  voiceActors(language: JAPANESE) {
                    id
                    name {
                      full
                    }
                    image {
                      medium
                    }
                  }
                }
              }
              externalLinks {
                id
                url
                site
                type
              }
              streamingEpisodes {
                title
                thumbnail
                url
                site
              }
              trailer {
                id
                site
                thumbnail
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
        """
        
        static let animeDetails = """
        query ($id: Int) {
          Media(id: $id, type: ANIME) {
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
            studios {
              nodes {
                id
                name
                isAnimationStudio
              }
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
            nextAiringEpisode {
              airingAt
              timeUntilAiring
              episode
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
                voiceActors(language: JAPANESE) {
                  id
                  name {
                    full
                  }
                  image {
                    medium
                  }
                }
              }
            }
            externalLinks {
              id
              url
              site
              type
            }
            streamingEpisodes {
              title
              thumbnail
              url
              site
            }
            trailer {
              id
              site
              thumbnail
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
        """
        
        static let animeRankings = """
        query ($id: Int) {
          Media(id: $id, type: ANIME) {
            id
            title {
              romaji
              english
              native
            }
            coverImage {
              large
            }
            popularity
            averageScore
            rankings {
              rank
              type
              context
              allTime
              season
              year
            }
          }
        }
        """
        
        // MARK: - Manga Queries
        
        static let mangaSearch = """
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
        """
        
        static let mangaDetails = """
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
        """
        
        // MARK: - Category Queries
        
        static let trendingAnime = """
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
        """
        
        static let trendingManga = """
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
        """
        
        // Add other query strings as needed...
    }
}
