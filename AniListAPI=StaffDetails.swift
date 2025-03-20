import Foundation

extension AniListAPI {
    /// Fetches staff details for a given staff ID.
    /// - Parameters:
    ///   - id: The ID of the staff member.
    ///   - completion: Completion handler returning an optional StaffDetail.
    func getStaffDetails(id: Int, completion: @escaping (StaffDetail?) -> Void) {
        let graphqlQuery: [String: Any] = [
            "query": """
            query ($id: Int) {
              Staff(id: $id) {
                id
                name {
                  first
                  last
                  full
                  native
                }
                image {
                  large
                }
                description
                primaryOccupations
                gender
                dateOfBirth {
                  year
                  month
                  day
                }
                dateOfDeath {
                  year
                  month
                  day
                }
                age
                yearsActive
                homeTown
                bloodType
                languageV2
                favourites
                characters(sort: FAVOURITES_DESC, page: 1, perPage: 20) {
                  edges {
                    role
                    node {
                      id
                      name {
                        full
                      }
                      image {
                        medium
                      }
                    }
                    media {
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
                characterMedia(sort: POPULARITY_DESC, page: 1, perPage: 20) {
                  edges {
                    characterRole
                    node {
                      id
                      title {
                        romaji
                        english
                      }
                      coverImage {
                        large
                      }
                    }
                    characters {
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
              }
            }
            """,
            "variables": ["id": id]
        ]
        
        guard let url = URL(string: self.apiURL) else {
            print("❌ Error: Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: graphqlQuery)
        } catch {
            print("❌ Error: Could not encode query JSON")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Error: No data received")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(StaffDetailResponse.self, from: data)
                print("✅ Successfully decoded staff: \(decodedResponse.data.Staff.name.full)")
                DispatchQueue.main.async {
                    completion(decodedResponse.data.Staff)
                }
            } catch {
                print("❌ JSON Decoding Error:", error)
                completion(nil)
            }
        }.resume()
    }
}
