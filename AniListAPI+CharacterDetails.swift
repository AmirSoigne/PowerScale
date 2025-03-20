import Foundation


extension AniListAPI {
    // MARK: - Character Detail Methods
    
    func getCharacterDetails(id: Int, completion: @escaping (CharacterDetail?) -> Void) {
        APIRequestThrottler.shared.executeRequest {
            let graphqlQuery: [String: Any] = [
                "query": """
                query ($id: Int) {
                  Character(id: $id) {
                    id
                    name {
                      first
                      last
                      full
                      native
                      alternative
                    }
                    image {
                      medium
                    }
                    description
                    gender
                    dateOfBirth {
                      year
                      month
                      day
                    }
                    age
                    bloodType
                    favourites
                    media(sort: POPULARITY_DESC, page: 1, perPage: 20) {
                      edges {
                        node {
                          id
                          type
                          title {
                            romaji
                            english
                          }
                          coverImage {
                            large
                          }
                          format
                          status
                          episodes
                          chapters
                        }
                        voiceActors(sort: LANGUAGE) {
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
                
                // Debug: Print the raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 Character API Raw Response: \(jsonString.prefix(500))...")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let decodedResponse = try decoder.decode(CharacterDetailResponse.self, from: data)
                    
                    print("✅ Successfully decoded character: \(decodedResponse.data.Character.name.full)")
                    
                    if let edges = decodedResponse.data.Character.media?.edges {
                        print("✅ Found \(edges.count) media appearances")
                        if let firstItem = edges.first,
                           let voiceActors = firstItem.voiceActors {
                            print("✅ Found \(voiceActors.count) voice actors for first appearance")
                        } else {
                            print("⚠️ No voice actors found in first appearance")
                        }
                    } else {
                        print("⚠️ No media appearances found")
                    }
                    
                    DispatchQueue.main.async {
                        completion(decodedResponse.data.Character)
                    }
                } catch {
                    print("❌ JSON Decoding Error:", error)
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response (first 500 chars): \(String(responseString.prefix(500)))")
                    }
                    completion(nil)
                }
            }.resume()
        }
        
        
        // MARK: - Staff/Voice Actor Detail Methods
        
        func getStaffDetails(id: Int, completion: @escaping (StaffDetail?) -> Void) {
            APIRequestThrottler.shared.executeRequest {
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
                    
                    // Debug: Print the raw JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📊 Staff API Raw Response: \(jsonString.prefix(500))...")
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let decodedResponse = try decoder.decode(StaffDetailResponse.self, from: data)
                        
                        // Debug: Print successful decode
                        print("✅ Successfully decoded staff: \(decodedResponse.data.Staff.name.full)")
                        
                        DispatchQueue.main.async {
                            completion(decodedResponse.data.Staff)
                        }
                    } catch {
                        print("❌ JSON Decoding Error:", error)
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Raw response (first 500 chars): \(String(responseString.prefix(500)))")
                        }
                        completion(nil)
                    }
                }.resume()
            }
        }
    }
}
